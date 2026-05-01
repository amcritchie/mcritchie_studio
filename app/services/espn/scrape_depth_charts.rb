require "net/http"
require "json"

# Scrapes ESPN's per-team depth chart pages and updates DepthChart entries.
# Source: https://www.espn.com/nfl/team/depth/_/name/{abbrev}
# Each page embeds the depth chart as JSON in `window['__espnfitt__']`.
#
# Behavior:
#   * Locked DepthChartEntry rows are never moved.
#   * ESPN-listed players get the depths ESPN assigned (skipping locked depths).
#   * Players already on our chart but not in ESPN's list keep their relative
#     order, slotted in after the ESPN-listed players.
#   * Players ESPN lists but we don't have are SKIPPED with a warning (we only
#     trust contracts + manual seed for who's actually on the team).
#
# Usage:
#   Espn::ScrapeDepthCharts.new.call                         # all 32 teams
#   Espn::ScrapeDepthCharts.new(team_abbrev: "buf").call     # single team
class Espn::ScrapeDepthCharts
  TEAM_ABBREV_TO_SLUG = {
    "buf" => "buffalo-bills",       "mia" => "miami-dolphins",
    "ne"  => "new-england-patriots", "nyj" => "new-york-jets",
    "bal" => "baltimore-ravens",    "cin" => "cincinnati-bengals",
    "cle" => "cleveland-browns",    "pit" => "pittsburgh-steelers",
    "hou" => "houston-texans",      "ind" => "indianapolis-colts",
    "jax" => "jacksonville-jaguars", "ten" => "tennessee-titans",
    "den" => "denver-broncos",      "kc"  => "kansas-city-chiefs",
    "lv"  => "las-vegas-raiders",   "lac" => "los-angeles-chargers",
    "dal" => "dallas-cowboys",      "nyg" => "new-york-giants",
    "phi" => "philadelphia-eagles", "wsh" => "washington-commanders",
    "chi" => "chicago-bears",       "det" => "detroit-lions",
    "gb"  => "green-bay-packers",   "min" => "minnesota-vikings",
    "atl" => "atlanta-falcons",     "car" => "carolina-panthers",
    "no"  => "new-orleans-saints",  "tb"  => "tampa-bay-buccaneers",
    "ari" => "arizona-cardinals",   "lar" => "los-angeles-rams",
    "sf"  => "san-francisco-49ers", "sea" => "seattle-seahawks"
  }.freeze

  # ESPN ST rows we ignore: holders, returners, gunners are derived from other positions
  IGNORED_POSITIONS = %w[H KR PR LH PH].freeze

  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"

  attr_reader :stats

  def initialize(team_abbrev: nil, verbose: false)
    @only_team = team_abbrev
    @verbose = verbose
    @stats = Hash.new(0)
  end

  def vputs(msg)
    puts msg if @verbose
  end

  def call
    abbrevs = @only_team ? [@only_team] : TEAM_ABBREV_TO_SLUG.keys
    abbrevs.each do |abbrev|
      slug = TEAM_ABBREV_TO_SLUG[abbrev]
      unless slug
        puts "  [?] Unknown ESPN abbrev: #{abbrev}"
        @stats[:teams_skipped] += 1
        next
      end
      scrape_team(abbrev, slug)
    end
    puts "\nESPN scrape complete: #{@stats.inspect}"
    @stats
  end

  private

  def scrape_team(abbrev, team_slug)
    chart = DepthChart.find_or_create_by!(team_slug: team_slug)
    @stats[:depth_charts_created] += 1 if chart.previously_new_record?

    groups = fetch_groups(abbrev)
    unless groups
      puts "  [!] Failed to parse depth chart for #{abbrev}"
      @stats[:teams_failed] += 1
      return
    end

    # Detect scheme from "Base 3-4 D" / "Base 4-3 D" group name and persist on
    # chart. Drives the scheme-aware Roster picker (3-4 WLB/SLB → EDGE, etc.).
    scheme = detect_scheme(groups)
    chart.update!(scheme: scheme) if scheme && chart.scheme != scheme

    # Tag each athlete with their raw formation slot ("WLB", "LDE", "NT") so
    # the picker can map formation→display per scheme. Each athlete becomes
    # a single-element "row" so the existing apply_row pipeline handles them
    # one at a time but preserves the formation_slot per entry.
    by_side_pos = Hash.new { |h, k| h[k] = [] }
    groups.each do |group|
      side = side_for_group(group["name"])
      next unless side
      group["rows"].each do |row|
        formation_slot = row[0].to_s.upcase
        next if IGNORED_POSITIONS.include?(formation_slot)
        position = normalize_position(formation_slot)
        row[1..].each do |athlete_data|
          next unless athlete_data
          tagged = athlete_data.merge("_formation_slot" => formation_slot)
          by_side_pos[[side, position]] << [tagged]
        end
      end
    end

    by_side_pos.each do |(side, position), rows|
      flattened = flatten_rows(rows)
      apply_row(chart, position, side, flattened, team_slug)
    end

    # Reconcile any same-side disagreements: ESPN's formation labels
    # (esp. 3-4 OLB vs 4-3 OLB) get collapsed to LB by ESPN_MAP, but our
    # athlete.position from nflverse correctly classifies edge rushers as
    # EDGE. Move the depth chart entry to match athlete.position so Maxx
    # Crosby (OLB→EDGE) is found in the EDGE pool by the Roster picker.
    reconcile_chart_positions(chart)

    # Re-densify depths everywhere — moves leave gaps at the source position.
    densify_chart(chart)

    puts "  [+] #{team_slug} (#{scheme || '?'}): applied ESPN depth chart"
    @stats[:teams_scraped] += 1
  end

  def detect_scheme(groups)
    groups.each do |g|
      name = g["name"].to_s
      return "3-4" if name =~ /3.?4/
      return "4-3" if name =~ /4.?3/
    end
    nil
  end

  # Defensive front-7 positions where ESPN's formation slot can disagree with
  # nflverse's player-role classification. ESPN labels by formation (LDE in
  # a 3-4 is interior DT; OLB in a 3-4 is an edge rusher) while nflverse
  # tracks the player's actual role across schemes. When chart.position and
  # athlete.position both fall in this set but differ, athlete.position wins.
  # Excluded by design: CB ↔ S (slot/big-nickel fluidity is real position
  # blending, not a labeling error).
  RECONCILE_FRONT7 = %w[EDGE DE DT NT DL DI LB ILB OLB MLB].freeze

  def reconcile_chart_positions(chart)
    chart.depth_chart_entries.includes(person: :athlete_profile).each do |entry|
      next if entry.locked
      ath_pos = entry.person&.athlete_profile&.position
      next if ath_pos.blank? || ath_pos == entry.position
      next unless reconcile_pair?(entry.position, ath_pos)

      # Player already has an entry at the canonical position on this chart
      # (e.g., a post-merge state where one entry came from each duplicate
      # Person). Drop the misplaced one — the canonical-position entry wins.
      twin = chart.depth_chart_entries
                  .where(person_slug: entry.person_slug, position: ath_pos)
                  .where.not(id: entry.id)
                  .first
      if twin
        entry.destroy
        @stats[:positions_deduped] += 1
        next
      end

      old_position = entry.position
      old_depth    = entry.depth

      # Bump existing entries at the target position with depth >= old_depth
      # down by one, preserving Crosby's starter slot at the new position.
      chart.depth_chart_entries
           .where(position: ath_pos)
           .where(locked: false)
           .where("depth >= ?", old_depth)
           .order(depth: :desc)
           .each { |other| other.update!(depth: other.depth + 1) }

      entry.update!(position: ath_pos)
      vputs "      [↔] #{entry.person.full_name}: #{old_position}#{old_depth} → #{ath_pos}#{old_depth}"
      @stats[:positions_reconciled] += 1
    end
  end

  def reconcile_pair?(chart_pos, athlete_pos)
    RECONCILE_FRONT7.include?(chart_pos) && RECONCILE_FRONT7.include?(athlete_pos)
  end

  def fetch_groups(abbrev)
    url = URI("https://www.espn.com/nfl/team/depth/_/name/#{abbrev}")
    req = Net::HTTP::Get.new(url)
    req["User-Agent"] = USER_AGENT
    res = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http| http.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)

    m = res.body.match(/__espnfitt__.*?=\s*(\{.*?\});\s*<\/script>/m)
    return nil unless m
    data = JSON.parse(m[1])
    data.dig("page", "content", "depth", "dethTeamGroups")
  rescue StandardError => e
    puts "  [!] Fetch error for #{abbrev}: #{e.message}"
    nil
  end

  def side_for_group(name)
    case name
    when /Special Teams/i        then "special_teams"
    when /\bD\b|Defense|Nickel|Base/i then "defense"
    else "offense"
    end
  end

  def normalize_position(espn_pos)
    PositionConcern.normalize_position(espn_pos, source: :espn)
  end

  # Round-robin flatten: row0[0], row1[0], row2[0], row0[1], row1[1], ...
  # Dedupes (ESPN sometimes cross-lists e.g. nickel CB in two slots).
  def flatten_rows(rows)
    max_depth = rows.map(&:size).max || 0
    out, seen = [], {}
    (0...max_depth).each do |col|
      rows.each do |row|
        athlete = row[col]
        next unless athlete
        key = athlete["uid"] || athlete["href"] || athlete["name"]
        next if seen[key]
        seen[key] = true
        out << athlete
      end
    end
    out
  end

  # Apply ESPN's depth ranking to a canonical (position, side):
  # 1. ESPN's order is preserved verbatim. If ESPN lists a brand-new player
  #    above an existing one, the new player gets the higher slot — this is
  #    the whole point of the weekly scrape (overwrite starters).
  # 2. Each player has at most one entry on the chart. If ESPN places them at
  #    a different position than their existing entry, MOVE the entry.
  # 3. Locked entries at this position keep their fixed depth.
  # 4. Existing entries at this position not in ESPN's list keep their
  #    relative order, slotting in BELOW ESPN's listed players.
  def apply_row(chart, position, side, athletes, team_slug)
    # Resolve persons ONCE (match_person has side effects: contract creation,
    # team_slug sync). Remember each athlete's raw formation slot so we can
    # persist it on the depth chart entry for the scheme-aware Roster picker.
    resolved = athletes.filter_map do |a|
      person = match_person(a, team_slug, position: position)
      next nil unless person
      [person, a["_formation_slot"]]
    end
    espn_persons  = resolved.map(&:first)
    formation_for = resolved.to_h { |person, fs| [person.slug, fs] }

    # Existing entry per ESPN-listed person on this chart. A player can
    # legitimately have only one entry at a given position, but post-merge
    # data can leave a person with multiple entries at DIFFERENT positions
    # (e.g., one carried over from each side of a duplicate-Person merge).
    # Prefer the entry already at our target position; drop the others so
    # the upcoming move doesn't violate the [chart, person, position]
    # uniqueness constraint.
    existing_for_espn = {}
    all_entries = chart.depth_chart_entries.where(person_slug: espn_persons.map(&:slug)).to_a
    all_entries.group_by(&:person_slug).each do |slug, entries|
      keep = entries.find { |e| e.position == position } || entries.first
      existing_for_espn[slug] = keep
      (entries - [keep]).each do |stale|
        next if stale.locked
        stale.destroy
        @stats[:stale_entries_pruned] += 1
      end
    end

    position_entries = chart.depth_chart_entries.where(position: position).to_a
    locked = position_entries.select(&:locked).sort_by(&:depth)
    locked_persons = locked.map(&:person_slug).to_set

    # Build the ordered list in ESPN's exact order. For each ESPN-listed
    # player, either reuse their existing entry (so we MOVE them here from
    # wherever they were) or build a new entry. Skip anyone whose entry is
    # already locked (manual overrides win).
    espn_ordered = espn_persons.map do |person|
      next nil if locked_persons.include?(person.slug)
      existing = existing_for_espn[person.slug]
      next nil if existing&.locked
      existing || chart.depth_chart_entries.build(person_slug: person.slug, position: position, side: side)
    end.compact

    new_count = espn_ordered.count(&:new_record?)

    # Existing players at this position whom ESPN didn't mention slot in below.
    unlisted = position_entries.reject { |e| e.locked || espn_ordered.include?(e) }
                               .sort_by(&:depth)

    ordered = espn_ordered + unlisted
    total = ordered.size + locked.size
    free_depths = (1..total).to_a - locked.map(&:depth)

    ordered.each_with_index do |entry, i|
      depth = free_depths[i] || (total + i + 1)
      attrs = { depth: depth, side: side, position: position }
      attrs[:formation_slot] = formation_for[entry.person_slug] if formation_for[entry.person_slug]
      entry.assign_attributes(attrs)
      entry.save!
    end

    @stats[:rows_applied] += 1
    @stats[:athletes_matched] += espn_persons.size
    @stats[:athletes_added] += new_count
  end

  # After moves, the source position may have depth gaps (1,2,4,5 with 3 missing).
  # Re-pack so every position runs 1..N, respecting locked depths.
  def densify_chart(chart)
    chart.depth_chart_entries.distinct.pluck(:position).each do |pos|
      entries = chart.depth_chart_entries.where(position: pos).order(:depth).to_a
      locked_depths = entries.select(&:locked).map(&:depth)
      unlocked = entries.reject(&:locked)

      free_depths = (1..entries.size).to_a - locked_depths
      unlocked.each_with_index do |e, i|
        target = free_depths[i] || (entries.size + i + 1)
        e.update!(depth: target) unless e.depth == target
      end
    end
  end

  # Resolve ESPN athlete → our Person, ensuring an active Contract exists for
  # this team. ESPN is now authoritative for "who is on the team this week" —
  # if ESPN places a player and we don't have them on this team, create the
  # Contract and expire any active contract on a different team (player moved).
  # Also keeps Athlete.team_slug in sync with the team the scraper just placed
  # them on.
  def match_person(athlete, team_slug, position: nil)
    espn_id = athlete["href"].to_s[%r{/id/(\d+)/}, 1]
    person, athlete_record = lookup_person(espn_id, athlete["name"] || athlete["displayName"])

    unless person
      vputs "      [?] no match: #{athlete['name']} (espn_id=#{espn_id})"
      @stats[:athletes_unmatched] += 1
      return nil
    end

    athlete_record ||= person.athlete_profile
    if athlete_record.nil?
      vputs "      [?] no athlete record: #{person.full_name}"
      @stats[:athletes_no_record] += 1
      return nil
    end

    ensure_active_contract(person, athlete_record, team_slug, position)
    person
  end

  def lookup_person(espn_id, name)
    if espn_id
      ath = Athlete.find_by(espn_id: espn_id)
      return [ath.person, ath] if ath
    end

    return [nil, nil] if name.blank?
    parts = strip_suffix(name).split(/\s+/, 2)
    return [nil, nil] if parts.size < 2

    person = Person.find_by_name(parts[0], parts[1])
    [person, person&.athlete_profile]
  end

  # Make Contract state agree with what ESPN just told us:
  #   1. Find or create active Contract for [person, team_slug]. If existing
  #      Contract was previously expired, un-expire it.
  #   2. Expire any other active Contracts the player has (they moved teams).
  #   3. Update Athlete.team_slug.
  def ensure_active_contract(person, athlete_record, team_slug, position)
    contract = Contract.find_or_initialize_by(person_slug: person.slug, team_slug: team_slug)
    if contract.new_record?
      contract.contract_type = "active"
      contract.position = position if position
      contract.save!
      @stats[:contracts_created] += 1
    elsif contract.expires_at && contract.expires_at < Date.today
      contract.update!(expires_at: nil, contract_type: "active")
      @stats[:contracts_revived] += 1
    end

    Contract.where(person_slug: person.slug, contract_type: "active")
            .where.not(team_slug: team_slug)
            .where("expires_at IS NULL OR expires_at >= ?", Date.today)
            .find_each do |stale|
      stale.update!(expires_at: Date.today - 1)
      @stats[:contracts_expired] += 1
    end

    if athlete_record.team_slug != team_slug
      athlete_record.update!(team_slug: team_slug)
      @stats[:team_slug_updates] += 1
    end
  end

  def strip_suffix(name)
    name.sub(/\s+(Jr\.?|Sr\.?|II|III|IV|V)\s*$/i, "").strip
  end
end
