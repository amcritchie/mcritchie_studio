# Real PFF grades — runs BEFORE 30_athlete_grades.rb so synthetic salary
# heuristic only fills gaps for athletes not present in any PFF CSV.
#
# Drop new PFF stat-summary CSVs into db/seeds/data/pff/ and reseed.
# Filenames must match a known stat_type (passing_summary.csv, defense_summary.csv, etc.)
# — see Pff::ImportCsv::GRADE_BACKFILL for the supported set.

pff_dir = Rails.root.join("db/seeds/data/pff")
season_slug = "2025-nfl"

unless Dir.exist?(pff_dir)
  puts "PFF: no db/seeds/data/pff/ directory, skipping"
else
  csvs = Dir.glob(pff_dir.join("*.csv")).sort
  if csvs.empty?
    puts "PFF: no CSVs in db/seeds/data/pff/, skipping"
  else
    csvs.each do |path|
      type = File.basename(path, ".csv").downcase.gsub(/\s+/, "_")
      puts "\n--- PFF #{type} (#{File.basename(path)}) ---"
      Pff::ImportCsv.new(csv_path: path, season_slug: season_slug, stat_type: type).call
    end
  end
end
