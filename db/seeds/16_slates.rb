# NFL 2025: Offseason + 18 regular weeks + 4 playoff rounds = 23 slates
nfl_season = Season.find_by(year: 2025, league: "nfl")

if nfl_season
  nfl_slates = [
    { sequence: 0,  label: "Offseason",         slate_type: "offseason" },
    { sequence: 1,  label: "Week 1",            slate_type: "regular",   starts_at: "2025-09-04", ends_at: "2025-09-08" },
    { sequence: 2,  label: "Week 2",            slate_type: "regular",   starts_at: "2025-09-11", ends_at: "2025-09-15" },
    { sequence: 3,  label: "Week 3",            slate_type: "regular",   starts_at: "2025-09-18", ends_at: "2025-09-22" },
    { sequence: 4,  label: "Week 4",            slate_type: "regular",   starts_at: "2025-09-25", ends_at: "2025-09-29" },
    { sequence: 5,  label: "Week 5",            slate_type: "regular",   starts_at: "2025-10-02", ends_at: "2025-10-06" },
    { sequence: 6,  label: "Week 6",            slate_type: "regular",   starts_at: "2025-10-09", ends_at: "2025-10-13" },
    { sequence: 7,  label: "Week 7",            slate_type: "regular",   starts_at: "2025-10-16", ends_at: "2025-10-20" },
    { sequence: 8,  label: "Week 8",            slate_type: "regular",   starts_at: "2025-10-23", ends_at: "2025-10-27" },
    { sequence: 9,  label: "Week 9",            slate_type: "regular",   starts_at: "2025-10-30", ends_at: "2025-11-03" },
    { sequence: 10, label: "Week 10",           slate_type: "regular",   starts_at: "2025-11-06", ends_at: "2025-11-10" },
    { sequence: 11, label: "Week 11",           slate_type: "regular",   starts_at: "2025-11-13", ends_at: "2025-11-17" },
    { sequence: 12, label: "Week 12",           slate_type: "regular",   starts_at: "2025-11-20", ends_at: "2025-11-24" },
    { sequence: 13, label: "Week 13",           slate_type: "regular",   starts_at: "2025-11-27", ends_at: "2025-12-01" },
    { sequence: 14, label: "Week 14",           slate_type: "regular",   starts_at: "2025-12-04", ends_at: "2025-12-08" },
    { sequence: 15, label: "Week 15",           slate_type: "regular",   starts_at: "2025-12-11", ends_at: "2025-12-15" },
    { sequence: 16, label: "Week 16",           slate_type: "regular",   starts_at: "2025-12-18", ends_at: "2025-12-22" },
    { sequence: 17, label: "Week 17",           slate_type: "regular",   starts_at: "2025-12-25", ends_at: "2025-12-29" },
    { sequence: 18, label: "Week 18",           slate_type: "regular",   starts_at: "2026-01-01", ends_at: "2026-01-05" },
    { sequence: 19, label: "Wild Card",          slate_type: "playoff",  starts_at: "2026-01-10", ends_at: "2026-01-12" },
    { sequence: 20, label: "Divisional Round",   slate_type: "playoff",  starts_at: "2026-01-17", ends_at: "2026-01-18" },
    { sequence: 21, label: "Conference Championship", slate_type: "playoff", starts_at: "2026-01-25", ends_at: "2026-01-25" },
    { sequence: 22, label: "Super Bowl",         slate_type: "playoff",  starts_at: "2026-02-08", ends_at: "2026-02-08" }
  ]

  nfl_slates.each do |data|
    slate = Slate.find_or_create_by!(season_slug: nfl_season.slug, sequence: data[:sequence]) do |s|
      s.label      = data[:label]
      s.slate_type = data[:slate_type]
      s.starts_at  = data[:starts_at]
      s.ends_at    = data[:ends_at]
    end
    puts "NFL Slate: #{slate.label} (#{slate.slug})"
  end
end

# FIFA 2025-26: 6 group matchdays
fifa_season = Season.find_by(year: 2025, league: "fifa")

if fifa_season
  (1..6).each do |md|
    slate = Slate.find_or_create_by!(season_slug: fifa_season.slug, sequence: md) do |s|
      s.label      = "Matchday #{md}"
      s.slate_type = "group"
    end
    puts "FIFA Slate: #{slate.label} (#{slate.slug})"
  end
end

puts "Slates: #{Slate.count} total"
