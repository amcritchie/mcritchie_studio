SEASONS = [
  { year: 2025, sport: "football", league: "nfl",  name: "2025 NFL Season",        active: true },
  { year: 2025, sport: "football", league: "ncaa", name: "2025 NCAA Football",     active: false },
  { year: 2025, sport: "soccer",   league: "fifa", name: "2025-26 FIFA World Cup", active: false }
]

SEASONS.each do |data|
  season = Season.find_or_create_by!(year: data[:year], league: data[:league]) do |s|
    s.sport  = data[:sport]
    s.name   = data[:name]
    s.active = data[:active]
  end
  puts "Season: #{season.name} (#{season.slug}) #{'[ACTIVE]' if season.active?}"
end
