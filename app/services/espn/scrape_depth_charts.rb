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

  # ESPN position labels → our dominant contract forms.
  # Most contracts use generic "LB", "EDGE", "S" rather than ESPN's formation-
  # specific WLB/LILB/RILB/SLB/LDE/RDE/FS/SS — collapse to match.
  ESPN_POSITION_MAP = {
    "LDE" => "EDGE", "RDE" => "EDGE", "DE" => "EDGE",
    "OLB" => "LB", "ILB" => "LB", "MLB" => "LB",
    "WLB" => "LB", "SLB" => "LB", "LILB" => "LB", "RILB" => "LB",
    "MIKE" => "LB", "WILL" => "LB", "SAM" => "LB",
    "LCB" => "CB", "RCB" => "CB", "NB" => "CB", "NCB" => "CB", "SCB" => "CB",
    "FS"  => "S",  "SS"  => "S",
    "PK"  => "K"
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
    chart = DepthChart.find_by(team_slug: team_slug)
    unless chart
      puts "  [?] No DepthChart for #{team_slug}"
      @stats[:teams_skipped] += 1
      return
    end

    groups = fetch_groups(abbrev)
    unless groups
      puts "  [!] Failed to parse depth chart for #{abbrev}"
      @stats[:teams_failed] += 1
      return
    end

    # ESPN models depth by formation slot (WR1/WR2/WR3 are 3 rows). We have one
    # chain per position, so flatten: take starters from every row first, then
    # second-stringers from every row, etc.
    by_side_pos = Hash.new { |h, k| h[k] = [] }
    groups.each do |group|
      side = side_for_group(group["name"])
      next unless side
      group["rows"].each do |row|
        espn_pos = row[0].to_s.upcase
        next if IGNORED_POSITIONS.include?(espn_pos)
        position = normalize_position(espn_pos)
        by_side_pos[[side, position]] << row[1..]
      end
    end

    by_side_pos.each do |(side, position), rows|
      flattened = flatten_rows(rows)
      apply_row(chart, position, side, flattened, team_slug)
    end

    # Re-densify depths everywhere — moves leave gaps at the source position.
    densify_chart(chart)

    puts "  [+] #{team_slug}: applied ESPN depth chart"
    @stats[:teams_scraped] += 1
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
    mapped = ESPN_POSITION_MAP[espn_pos] || espn_pos
    PositionConcern.normalize_position(mapped)
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
  # 1. Each player has at most one entry in the chart. If ESPN places them at
  #    a different position than their existing entry, MOVE the entry.
  # 2. Locked entries at this position keep their fixed depth.
  # 3. Existing entries at this position not in ESPN's list keep their relative
  #    order, slotting in after ESPN-listed entries.
  def apply_row(chart, position, side, athletes, team_slug)
    espn_persons = athletes.map { |a| match_person(a, team_slug) }.compact

    # Existing entry per ESPN-listed person (might be at any position)
    existing_for_espn = chart.depth_chart_entries
                             .where(person_slug: espn_persons.map(&:slug))
                             .index_by(&:person_slug)

    position_entries = chart.depth_chart_entries.where(position: position).to_a
    locked = position_entries.select(&:locked).sort_by(&:depth)

    espn_listed = espn_persons.map { |p| existing_for_espn[p.slug] }.compact
    espn_unlocked = espn_listed.reject(&:locked)

    unlisted = position_entries.reject { |e| e.locked || espn_listed.include?(e) }
                               .sort_by(&:depth)

    new_persons = espn_persons.reject { |p| existing_for_espn.key?(p.slug) }
    new_entries = new_persons.map do |person|
      chart.depth_chart_entries.build(person_slug: person.slug, position: position, side: side)
    end

    ordered = espn_unlocked + new_entries + unlisted
    total = ordered.size + locked.size
    free_depths = (1..total).to_a - locked.map(&:depth)

    ordered.each_with_index do |entry, i|
      depth = free_depths[i] || (total + i + 1)
      entry.assign_attributes(depth: depth, side: side, position: position)
      entry.save!
    end

    @stats[:rows_applied] += 1
    @stats[:athletes_matched] += espn_persons.size
    @stats[:athletes_unmatched] += athletes.size - espn_persons.size
    @stats[:athletes_added] += new_entries.size
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

  # Resolve ESPN athlete → our Person, but ONLY if they have an active contract
  # with this team. Otherwise ESPN's depth chart drift (recent trades, mid-season
  # signings) would pollute our charts with players actually on other teams.
  def match_person(athlete, team_slug)
    espn_id = athlete["href"].to_s[%r{/id/(\d+)/}, 1]
    person = nil
    if espn_id
      ath = Athlete.find_by(espn_id: espn_id)
      person = ath&.person
    end

    unless person
      full_name = athlete["name"] || athlete["displayName"] || ""
      parts = strip_suffix(full_name).split(/\s+/, 2)
      person = Person.find_by_name(parts[0], parts[1]) if parts.size == 2
    end

    unless person
      vputs "      [?] no match: #{athlete['name']} (espn_id=#{espn_id})"
      return nil
    end

    on_team = Contract.where(person_slug: person.slug, team_slug: team_slug, contract_type: "active").exists?
    unless on_team
      vputs "      [~] cross-team skip: #{person.full_name} (on chart for #{team_slug}, no active contract)"
      @stats[:athletes_cross_team] += 1
      return nil
    end

    person
  end

  def strip_suffix(name)
    name.sub(/\s+(Jr\.?|Sr\.?|II|III|IV|V)\s*$/i, "").strip
  end
end
