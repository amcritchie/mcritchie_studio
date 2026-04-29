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
end
