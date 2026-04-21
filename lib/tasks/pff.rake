namespace :pff do
  desc "Import PFF starting lineup CSV. FILE=path/to/csv SEASON=2025-nfl"
  task import_starters: :environment do
    file   = ENV.fetch("FILE", Rails.root.join("lib/pff/starting-lineups-2025.csv").to_s)
    season = ENV.fetch("SEASON", "2025-nfl")

    unless File.exist?(file)
      puts "File not found: #{file}"
      puts "Copy PFF CSV to lib/pff/ and retry, or pass FILE=path/to/csv"
      exit 1
    end

    puts "Importing PFF starters from #{file} for season #{season}..."
    Pff::ImportStarters.new(csv_path: file, season_slug: season).call
  end
end
