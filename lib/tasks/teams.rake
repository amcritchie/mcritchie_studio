require "csv"

namespace :teams do
  desc "Backfill Team#hashtag from db/seeds/data/teams_hashtags.csv (matches by short_name)"
  task backfill_hashtags: :environment do
    path = Rails.root.join("db/seeds/data/teams_hashtags.csv")
    abort("missing #{path}") unless File.exist?(path)

    matched = 0
    missing = []
    CSV.foreach(path, headers: true) do |row|
      short = row["Short"]&.strip
      tag   = row["Hashtag"]&.strip
      next if short.blank? || tag.blank?

      team = Team.find_by(short_name: short, league: "nfl")
      if team
        team.update!(hashtag: tag)
        matched += 1
      else
        missing << short
      end
    end

    puts "matched: #{matched}"
    puts "missing: #{missing.inspect}" if missing.any?
  end
end
