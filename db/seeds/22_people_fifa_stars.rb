# 48 FIFA Stars — one per World Cup 2026 team
FIFA_STARS = [
  # Group A
  { first_name: "Hirving",      last_name: "Lozano",          position: "FW", team_slug: "mexico" },
  { first_name: "Son",          last_name: "Heung-min",       position: "FW", team_slug: "south-korea" },
  { first_name: "Percy",        last_name: "Tau",             position: "FW", team_slug: "south-africa" },
  { first_name: "Patrik",       last_name: "Schick",          position: "FW", team_slug: "czechia" },

  # Group B
  { first_name: "Alphonso",     last_name: "Davies",          position: "DF", team_slug: "canada" },
  { first_name: "Edin",         last_name: "Dzeko",           position: "FW", team_slug: "bosnia-and-herzegovina" },
  { first_name: "Akram",        last_name: "Afif",            position: "FW", team_slug: "qatar" },
  { first_name: "Granit",       last_name: "Xhaka",           position: "MF", team_slug: "switzerland" },

  # Group C
  { first_name: "Vinicius",     last_name: "Junior",          position: "FW", team_slug: "brazil" },
  { first_name: "Achraf",       last_name: "Hakimi",          position: "DF", team_slug: "morocco" },
  { first_name: "Duckens",      last_name: "Nazon",           position: "FW", team_slug: "haiti" },
  { first_name: "Andrew",       last_name: "Robertson",       position: "DF", team_slug: "scotland" },

  # Group D
  { first_name: "Christian",    last_name: "Pulisic",         position: "FW", team_slug: "united-states" },
  { first_name: "Miguel",       last_name: "Almiron",         position: "MF", team_slug: "paraguay" },
  { first_name: "Mathew",       last_name: "Leckie",          position: "FW", team_slug: "australia" },
  { first_name: "Hakan",        last_name: "Calhanoglu",      position: "MF", team_slug: "turkiye" },

  # Group E
  { first_name: "Florian",      last_name: "Wirtz",           position: "MF", team_slug: "germany" },
  { first_name: "Juninho",      last_name: "Bacuna",          position: "MF", team_slug: "curacao" },
  { first_name: "Simon",        last_name: "Adingra",         position: "FW", team_slug: "ivory-coast" },
  { first_name: "Moises",       last_name: "Caicedo",         position: "MF", team_slug: "ecuador" },

  # Group F
  { first_name: "Virgil",       last_name: "van Dijk",        position: "DF", team_slug: "netherlands" },
  { first_name: "Takefusa",     last_name: "Kubo",            position: "FW", team_slug: "japan" },
  { first_name: "Alexander",    last_name: "Isak",            position: "FW", team_slug: "sweden" },
  { first_name: "Youssef",      last_name: "Msakni",          position: "FW", team_slug: "tunisia" },

  # Group G
  { first_name: "Kevin",        last_name: "De Bruyne",       position: "MF", team_slug: "belgium" },
  { first_name: "Mohamed",      last_name: "Salah",           position: "FW", team_slug: "egypt" },
  { first_name: "Mehdi",        last_name: "Taremi",          position: "FW", team_slug: "iran" },
  { first_name: "Chris",        last_name: "Wood",            position: "FW", team_slug: "new-zealand" },

  # Group H
  { first_name: "Pedri",        last_name: "Gonzalez",        position: "MF", team_slug: "spain" },
  { first_name: "Ryan",         last_name: "Mendes",          position: "FW", team_slug: "cape-verde" },
  { first_name: "Salem",        last_name: "Al-Dawsari",      position: "FW", team_slug: "saudi-arabia" },
  { first_name: "Federico",     last_name: "Valverde",        position: "MF", team_slug: "uruguay" },

  # Group I
  { first_name: "Kylian",       last_name: "Mbappe",          position: "FW", team_slug: "france" },
  { first_name: "Sadio",        last_name: "Mane",            position: "FW", team_slug: "senegal" },
  { first_name: "Mohanad",      last_name: "Ali",             position: "FW", team_slug: "iraq" },
  { first_name: "Erling",       last_name: "Haaland",         position: "FW", team_slug: "norway" },

  # Group J
  { first_name: "Lionel",       last_name: "Messi",           position: "FW", team_slug: "argentina" },
  { first_name: "Riyad",        last_name: "Mahrez",          position: "FW", team_slug: "algeria" },
  { first_name: "David",        last_name: "Alaba",           position: "DF", team_slug: "austria" },
  { first_name: "Mousa",        last_name: "Al-Taamari",      position: "FW", team_slug: "jordan" },

  # Group K
  { first_name: "Cristiano",    last_name: "Ronaldo",         position: "FW", team_slug: "portugal" },
  { first_name: "Chancel",      last_name: "Mbemba",          position: "DF", team_slug: "dr-congo" },
  { first_name: "Eldor",        last_name: "Shomurodov",      position: "FW", team_slug: "uzbekistan" },
  { first_name: "Luis",         last_name: "Diaz",            position: "FW", team_slug: "colombia" },

  # Group L
  { first_name: "Jude",         last_name: "Bellingham",      position: "MF", team_slug: "england" },
  { first_name: "Luka",         last_name: "Modric",          position: "MF", team_slug: "croatia" },
  { first_name: "Mohammed",     last_name: "Kudus",           position: "MF", team_slug: "ghana" },
  { first_name: "Jose",         last_name: "Fajardo",         position: "FW", team_slug: "panama" },
]

FIFA_STARS.each do |data|
  slug = "#{data[:first_name]} #{data[:last_name]}".parameterize

  person = Person.find_or_create_by!(slug: slug) do |p|
    p.first_name = data[:first_name]
    p.last_name = data[:last_name]
    p.athlete = true
  end
  person.update!(athlete: true) unless person.athlete?

  Athlete.find_or_create_by!(person_slug: slug) do |a|
    a.sport = "soccer"
    a.position = data[:position]
  end

  Contract.find_or_create_by!(person_slug: slug, team_slug: data[:team_slug]) do |c|
    c.position = data[:position]
  end

  puts "FIFA Star: #{person.full_name} (#{data[:position]}) - #{data[:team_slug]}"
end
