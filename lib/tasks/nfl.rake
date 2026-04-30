namespace :nfl do
  ROSTER_URL = "https://github.com/nflverse/nflverse-data/releases/download/rosters/roster_2025.csv"

  desc "Pull nflverse rosters; populate Athlete espn_id + espn_headshot_url. No S3 traffic."
  task link_headshots: :environment do
    require "csv"
    require "open-uri"

    teams_by_code = Team.where(league: "nfl").index_by(&:short_name).merge("LA" => Team.find_by(slug: "los-angeles-rams"))

    puts "Fetching #{ROSTER_URL}"
    csv = CSV.parse(URI.open(ROSTER_URL).read.force_encoding("UTF-8"), headers: true)
    puts "  #{csv.size} rows"

    matched = 0
    skipped_no_espn = 0
    skipped_no_person = 0
    skipped_no_athlete = 0
    skipped_unchanged = 0

    csv.each do |row|
      espn_id = row["espn_id"].to_s.strip
      next skipped_no_espn += 1 if espn_id.empty?

      slug = "#{row["first_name"]} #{row["last_name"]}".parameterize
      person = Person.find_by(slug: slug)
      next skipped_no_person += 1 unless person

      athlete = person.athlete_profile
      next skipped_no_athlete += 1 unless athlete

      espn_url = "https://a.espncdn.com/i/headshots/nfl/players/full/#{espn_id}.png"

      if athlete.espn_id == espn_id && athlete.espn_headshot_url == espn_url
        skipped_unchanged += 1
        next
      end

      athlete.update!(espn_id: espn_id, espn_headshot_url: espn_url)
      matched += 1
      puts "  [+] #{slug.ljust(28)} espn_id=#{espn_id}" if matched <= 10 || (matched % 100).zero?
    end

    puts ""
    puts "matched/updated:        #{matched}"
    puts "skipped (unchanged):    #{skipped_unchanged}"
    puts "skipped (no espn_id):   #{skipped_no_espn}"
    puts "skipped (no Person):    #{skipped_no_person}"
    puts "skipped (no Athlete):   #{skipped_no_athlete}"
  end

  HEADSHOT_WIDTHS = [100, 400].freeze

  desc "For Athletes with espn_id, cache headshot variants in S3 + ImageCache. Idempotent."
  task upload_headshots: :environment do
    candidates = Athlete.where.not(espn_id: nil).includes(person: { contracts: :team }, image_caches: {})
    puts "candidates: #{candidates.count} athletes; widths: #{HEADSHOT_WIDTHS.inspect}"

    cached = 0
    skipped_complete = 0
    skipped_no_team = 0
    failed = 0

    candidates.find_each do |athlete|
      person = athlete.person
      contract = person.contracts.find { |c| c.team&.league == "nfl" }
      team = contract&.team

      unless team
        skipped_no_team += 1
        next
      end

      have = athlete.image_caches.select { |c| c.purpose == "headshot" }.map(&:variant)
      if (HEADSHOT_WIDTHS.map(&:to_s) - have).empty?
        skipped_complete += 1
        next
      end

      key_prefix = "headshots/nfl/#{team.slug}/#{person.slug}"

      begin
        Studio::ImageCache.cache!(
          owner: athlete,
          purpose: "headshot",
          source_url: athlete.espn_headshot_url,
          key_prefix: key_prefix,
          widths: HEADSHOT_WIDTHS,
          content_type: "image/png"
        )
        cached += 1
        puts "  [+] #{person.slug.ljust(28)} -> #{key_prefix}/{original,#{HEADSHOT_WIDTHS.join(',')}}.png" if cached <= 5 || (cached % 50).zero?
      rescue => e
        failed += 1
        puts "  [!] #{person.slug}: #{e.class}: #{e.message}"
      end
    end

    puts ""
    puts "cached:                 #{cached}"
    puts "skipped (already done): #{skipped_complete}"
    puts "skipped (no NFL team):  #{skipped_no_team}"
    puts "failed:                 #{failed}"
  end

  ESPN_TEAMS_INDEX_URL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams"
  ESPN_TEAM_COACHES_URL = ->(team_id) { "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/teams/#{team_id}/coaches" }
  COACH_HEADSHOT_WIDTHS = [100, 400].freeze

  desc "Pull NFL head coaches from ESPN; populate Coach espn_id + espn_headshot_url. No S3 traffic."
  task link_coach_headshots: :environment do
    require "open-uri"
    require "json"

    teams_by_abbrev = Team.where(league: "nfl").index_by(&:short_name).merge(
      "LA"  => Team.find_by(slug: "los-angeles-rams"),
      "WSH" => Team.find_by(slug: "washington-commanders")
    )

    puts "Fetching ESPN team index..."
    teams_resp = JSON.parse(URI.open(ESPN_TEAMS_INDEX_URL).read)
    espn_teams = teams_resp.dig("sports", 0, "leagues", 0, "teams").map { |t| t["team"] }
    puts "  #{espn_teams.size} ESPN teams"

    matched = 0
    skipped_unchanged = 0
    skipped_no_team = 0
    skipped_no_coach = 0
    failed = 0

    espn_teams.each do |et|
      espn_team_id = et["id"]
      espn_abbrev  = et["abbreviation"]
      our_team     = teams_by_abbrev[espn_abbrev]

      unless our_team
        skipped_no_team += 1
        puts "  [?] No team match for ESPN abbrev=#{espn_abbrev}"
        next
      end

      coaches_resp = JSON.parse(URI.open(ESPN_TEAM_COACHES_URL.call(espn_team_id)).read)
      ref = coaches_resp.dig("items", 0, "$ref")
      unless ref
        skipped_no_coach += 1
        next
      end

      coach_resp = JSON.parse(URI.open(ref).read)
      espn_id = coach_resp["id"].to_s
      headshot_url = coach_resp.dig("headshot", "href")
      first = coach_resp["firstName"]
      last  = coach_resp["lastName"]
      espn_person_slug = "#{first} #{last}".parameterize

      coach = Coach.find_by(team_slug: our_team.slug, role: "head_coach", person_slug: espn_person_slug) ||
              Coach.find_by(team_slug: our_team.slug, role: "head_coach")

      unless coach
        skipped_no_coach += 1
        puts "  [?] #{our_team.slug.ljust(25)} no Coach record (ESPN HC: #{first} #{last})"
        next
      end

      if coach.person_slug != espn_person_slug
        puts "  [~] #{our_team.slug.ljust(25)} ESPN says HC=#{first} #{last}, we have #{coach.person.full_name}"
      end

      if coach.espn_id == espn_id && coach.espn_headshot_url == headshot_url
        skipped_unchanged += 1
      else
        coach.update!(espn_id: espn_id, espn_headshot_url: headshot_url)
        matched += 1
        puts "  [+] #{our_team.slug.ljust(25)} #{first} #{last} (espn_id=#{espn_id})"
      end
    rescue => e
      failed += 1
      puts "  [!] error for #{espn_abbrev}: #{e.class}: #{e.message}"
    end

    puts ""
    puts "matched/updated:      #{matched}"
    puts "skipped (unchanged):  #{skipped_unchanged}"
    puts "skipped (no team):    #{skipped_no_team}"
    puts "skipped (no Coach):   #{skipped_no_coach}"
    puts "failed:               #{failed}"
  end

  desc "For Coaches with espn_id + espn_headshot_url, cache variants. Idempotent."
  task upload_coach_headshots: :environment do
    with_url    = Coach.where.not(espn_id: nil).where.not(espn_headshot_url: nil).includes(:image_caches)
    without_url = Coach.where.not(espn_id: nil).where(espn_headshot_url: nil).count
    puts "candidates: #{with_url.count} coaches with headshot URL; #{without_url} ESPN-known but no image; widths: #{COACH_HEADSHOT_WIDTHS.inspect}"

    cached = 0
    skipped_complete = 0
    failed = 0

    with_url.find_each do |coach|
      have = coach.image_caches.select { |c| c.purpose == "headshot" }.map(&:variant)
      if (["original"] + COACH_HEADSHOT_WIDTHS.map(&:to_s) - have).empty?
        skipped_complete += 1
        next
      end

      key_prefix = "headshots/nfl/coaches/#{coach.person_slug}"
      content_type = coach.espn_headshot_url.to_s.end_with?(".png") ? "image/png" : "image/jpeg"

      begin
        Studio::ImageCache.cache!(
          owner: coach,
          purpose: "headshot",
          source_url: coach.espn_headshot_url,
          key_prefix: key_prefix,
          widths: COACH_HEADSHOT_WIDTHS,
          content_type: content_type
        )
        cached += 1
        puts "  [+] #{coach.person_slug.ljust(28)} (#{coach.team_slug})"
      rescue => e
        failed += 1
        puts "  [!] #{coach.person_slug}: #{e.class}: #{e.message}"
      end
    end

    puts ""
    puts "cached:                 #{cached}"
    puts "skipped (already done): #{skipped_complete}"
    puts "skipped (no ESPN img):  #{without_url}"
    puts "failed:                 #{failed}"
  end
end
