# 48 FIFA World Cup 2026 Teams × 1 Head Coach = 48 records
FIFA_COACHES = [
  # Group A
  { team: "Mexico",                    coach: "Javier Aguirre" },
  { team: "South Korea",              coach: "Hong Myung-bo" },
  { team: "South Africa",             coach: "Hugo Broos" },
  { team: "Czechia",                   coach: "Miroslav Koubek" },
  # Group B
  { team: "Canada",                    coach: "Jesse Marsch" },
  { team: "Bosnia and Herzegovina",    coach: "Sergej Barbarez" },
  { team: "Qatar",                     coach: "Julen Lopetegui" },
  { team: "Switzerland",              coach: "Murat Yakin" },
  # Group C
  { team: "Brazil",                    coach: "Carlo Ancelotti" },
  { team: "Morocco",                   coach: "Mohamed Ouahbi" },
  { team: "Haiti",                     coach: "Sebastien Migne" },
  { team: "Scotland",                  coach: "Steve Clarke" },
  # Group D
  { team: "United States",            coach: "Mauricio Pochettino" },
  { team: "Paraguay",                  coach: "Gustavo Alfaro" },
  { team: "Australia",                 coach: "Tony Popovic" },
  { team: "T\u00FCrkiye",            coach: "Vincenzo Montella" },
  # Group E
  { team: "Germany",                   coach: "Julian Nagelsmann" },
  { team: "Cura\u00E7ao",            coach: "Fred Rutten" },
  { team: "Ivory Coast",              coach: "Emerse Fae" },
  { team: "Ecuador",                   coach: "Sebastian Beccacece" },
  # Group F
  { team: "Netherlands",              coach: "Ronald Koeman" },
  { team: "Japan",                     coach: "Hajime Moriyasu" },
  { team: "Sweden",                    coach: "Graham Potter" },
  { team: "Tunisia",                   coach: "Sabri Lamouchi" },
  # Group G
  { team: "Belgium",                   coach: "Rudi Garcia" },
  { team: "Egypt",                     coach: "Hossam Hassan" },
  { team: "Iran",                      coach: "Amir Ghalenoei" },
  { team: "New Zealand",              coach: "Darren Bazeley" },
  # Group H
  { team: "Spain",                     coach: "Luis de la Fuente" },
  { team: "Cape Verde",               coach: "Bubista" },
  { team: "Saudi Arabia",             coach: "Georgios Donis" },
  { team: "Uruguay",                   coach: "Marcelo Bielsa" },
  # Group I
  { team: "France",                    coach: "Didier Deschamps" },
  { team: "Senegal",                   coach: "Pape Thiaw" },
  { team: "Iraq",                      coach: "Graham Arnold" },
  { team: "Norway",                    coach: "Stale Solbakken" },
  # Group J
  { team: "Argentina",                coach: "Lionel Scaloni" },
  { team: "Algeria",                   coach: "Vladimir Petkovic" },
  { team: "Austria",                   coach: "Ralf Rangnick" },
  { team: "Jordan",                    coach: "Jamal Sellami" },
  # Group K
  { team: "Portugal",                  coach: "Roberto Martinez" },
  { team: "DR Congo",                  coach: "Sebastien Desabre" },
  { team: "Uzbekistan",               coach: "Fabio Cannavaro" },
  { team: "Colombia",                  coach: "Nestor Lorenzo" },
  # Group L
  { team: "England",                   coach: "Thomas Tuchel" },
  { team: "Croatia",                   coach: "Zlatko Dalic" },
  { team: "Ghana",                     coach: "Carlos Queiroz" },
  { team: "Panama",                    coach: "Thomas Christiansen" },
]

FIFA_COACHES.each do |data|
  team_slug = data[:team].parameterize
  team = Team.find_by(slug: team_slug)
  unless team
    puts "  [!] FIFA team not found: #{data[:team]}"
    next
  end

  parts = data[:coach].split(/\s+/, 2)
  first_name = parts[0]
  last_name  = parts[1].presence || parts[0]

  person = Person.find_or_create_by_name!(first_name, last_name, coach: true)

  Coach.find_or_create_by!(
    person_slug: person.slug,
    team_slug: team.slug,
    role: "head_coach"
  ) do |c|
    c.sport = "soccer"
  end

  puts "  FIFA Coach: #{team.emoji} #{team.name} — #{data[:coach]}"
end
