# 32 NFL Stars — highest-paid player per team (2025 season)
NFL_STARS = [
  # AFC East
  { first_name: "Josh",      last_name: "Allen",         position: "QB",   team_slug: "buffalo-bills",           annual_value_cents: 5_500_000_000 },
  { first_name: "Tua",       last_name: "Tagovailoa",    position: "QB",   team_slug: "miami-dolphins",          annual_value_cents: 5_310_000_000 },
  { first_name: "Milton",    last_name: "Williams",      position: "DL",   team_slug: "new-england-patriots",    annual_value_cents: 2_600_000_000 },
  { first_name: "Garrett",   last_name: "Wilson",        position: "WR",   team_slug: "new-york-jets",           annual_value_cents: 3_250_000_000 },

  # AFC North
  { first_name: "Lamar",     last_name: "Jackson",       position: "QB",   team_slug: "baltimore-ravens",        annual_value_cents: 5_200_000_000 },
  { first_name: "Joe",       last_name: "Burrow",        position: "QB",   team_slug: "cincinnati-bengals",      annual_value_cents: 5_500_000_000 },
  { first_name: "Myles",     last_name: "Garrett",       position: "DE",   team_slug: "cleveland-browns",        annual_value_cents: 4_000_000_000 },
  { first_name: "T.J.",      last_name: "Watt",          position: "OLB",  team_slug: "pittsburgh-steelers",     annual_value_cents: 4_100_000_000 },

  # AFC South
  { first_name: "Danielle",  last_name: "Hunter",        position: "DE",   team_slug: "houston-texans",          annual_value_cents: 3_560_000_000 },
  { first_name: "Michael",   last_name: "Pittman Jr.",   position: "WR",   team_slug: "indianapolis-colts",      annual_value_cents: 2_330_000_000 },
  { first_name: "Trevor",    last_name: "Lawrence",      position: "QB",   team_slug: "jacksonville-jaguars",    annual_value_cents: 5_500_000_000 },
  { first_name: "Jeffery",   last_name: "Simmons",       position: "DT",   team_slug: "tennessee-titans",        annual_value_cents: 2_350_000_000 },

  # AFC West
  { first_name: "Patrick",   last_name: "Surtain II",    position: "CB",   team_slug: "denver-broncos",          annual_value_cents: 2_400_000_000 },
  { first_name: "Patrick",   last_name: "Mahomes",       position: "QB",   team_slug: "kansas-city-chiefs",      annual_value_cents: 4_500_000_000 },
  { first_name: "Geno",      last_name: "Smith",         position: "QB",   team_slug: "las-vegas-raiders",       annual_value_cents: 3_750_000_000 },
  { first_name: "Justin",    last_name: "Herbert",       position: "QB",   team_slug: "los-angeles-chargers",    annual_value_cents: 5_250_000_000 },

  # NFC East
  { first_name: "Dak",       last_name: "Prescott",      position: "QB",   team_slug: "dallas-cowboys",          annual_value_cents: 6_000_000_000 },
  { first_name: "Brian",     last_name: "Burns",         position: "DE",   team_slug: "new-york-giants",         annual_value_cents: 2_820_000_000 },
  { first_name: "Jalen",     last_name: "Hurts",         position: "QB",   team_slug: "philadelphia-eagles",     annual_value_cents: 5_100_000_000 },
  { first_name: "Laremy",    last_name: "Tunsil",        position: "OT",   team_slug: "washington-commanders",   annual_value_cents: 2_500_000_000 },

  # NFC North
  { first_name: "D.J.",      last_name: "Moore",         position: "WR",   team_slug: "chicago-bears",           annual_value_cents: 2_750_000_000 },
  { first_name: "Jared",     last_name: "Goff",          position: "QB",   team_slug: "detroit-lions",           annual_value_cents: 5_300_000_000 },
  { first_name: "Jordan",    last_name: "Love",          position: "QB",   team_slug: "green-bay-packers",       annual_value_cents: 5_500_000_000 },
  { first_name: "Justin",    last_name: "Jefferson",     position: "WR",   team_slug: "minnesota-vikings",       annual_value_cents: 3_500_000_000 },

  # NFC South
  { first_name: "Kirk",      last_name: "Cousins",       position: "QB",   team_slug: "atlanta-falcons",         annual_value_cents: 4_500_000_000 },
  { first_name: "Jaycee",    last_name: "Horn",          position: "CB",   team_slug: "carolina-panthers",       annual_value_cents: 2_500_000_000 },
  { first_name: "Derek",     last_name: "Carr",          position: "QB",   team_slug: "new-orleans-saints",      annual_value_cents: 3_750_000_000 },
  { first_name: "Baker",     last_name: "Mayfield",      position: "QB",   team_slug: "tampa-bay-buccaneers",    annual_value_cents: 3_330_000_000 },

  # NFC West
  { first_name: "Kyler",     last_name: "Murray",        position: "QB",   team_slug: "arizona-cardinals",       annual_value_cents: 4_610_000_000 },
  { first_name: "Matthew",   last_name: "Stafford",      position: "QB",   team_slug: "los-angeles-rams",        annual_value_cents: 4_000_000_000 },
  { first_name: "Brock",     last_name: "Purdy",         position: "QB",   team_slug: "san-francisco-49ers",     annual_value_cents: 5_300_000_000 },
  { first_name: "Sam",       last_name: "Darnold",       position: "QB",   team_slug: "seattle-seahawks",        annual_value_cents: 3_350_000_000 },
]

NFL_STARS.each do |data|
  slug = "#{data[:first_name]} #{data[:last_name]}".parameterize

  person = Person.find_or_create_by!(slug: slug) do |p|
    p.first_name = data[:first_name]
    p.last_name = data[:last_name]
    p.athlete = true
  end
  person.update!(athlete: true) unless person.athlete?

  Athlete.find_or_create_by!(person_slug: slug) do |a|
    a.sport = "football"
    a.position = data[:position]
  end

  Contract.find_or_create_by!(person_slug: slug, team_slug: data[:team_slug]) do |c|
    c.annual_value_cents = data[:annual_value_cents]
    c.position = data[:position]
  end

  puts "NFL Star: #{person.full_name} (#{data[:position]}) - $#{data[:annual_value_cents] / 100}/yr"
end
