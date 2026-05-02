require "csv"

namespace :teams do
  desc "Backfill Team#hashtag, hashtag2, x_handle from db/seeds/data/teams_hashtags.csv (matches by short_name)"
  task backfill_metadata: :environment do
    path = Rails.root.join("db/seeds/data/teams_hashtags.csv")
    abort("missing #{path}") unless File.exist?(path)

    matched = 0
    missing = []
    CSV.foreach(path, headers: true) do |row|
      short = row["Short"]&.strip
      next if short.blank?

      team = Team.find_by(short_name: short, league: "nfl")
      unless team
        missing << short
        next
      end

      attrs = {
        hashtag:  row["Hashtag"]&.strip.presence,
        hashtag2: row["HT2"]&.strip.presence,
        x_handle: row["X"]&.strip.presence
      }.compact

      team.update!(attrs) if attrs.any?
      matched += 1
    end

    puts "teams metadata — matched: #{matched}"
    puts "missing: #{missing.inspect}" if missing.any?
  end

  # Back-compat alias — old name still works.
  task backfill_hashtags: :backfill_metadata
end
