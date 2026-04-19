# Users
users_data = [
  { name: "Alex McRitchie",  email: "alex@mcritchie.studio",  role: "admin" },
  { name: "Mason McRitchie", email: "mason@mcritchie.studio", role: "admin" },
  { name: "Mack McRitchie",  email: "mack@mcritchie.studio",  role: "admin" },
  { name: "Turf Monster",    email: "turf@mcritchie.studio",  role: "admin" }
]

users_data.each do |data|
  user = User.find_or_create_by!(email: data[:email]) do |u|
    u.name = data[:name]
    u.password = "password"
    u.role = data[:role]
  end
  puts "User: #{user.email} (#{user.role})"
end

# Agents
agents_data = [
  {
    name: "Alex",
    slug: "alex",
    status: "active",
    agent_type: "orchestrator",
    title: "Lead Orchestrator",
    description: "Coordinates all agents, manages task assignment, and oversees system operations. The central brain of McRitchie Studio.",
    avatar: "/agents/alex.png",
    position: 0
  },
  {
    name: "Turf Monster",
    slug: "turf-monster",
    status: "active",
    agent_type: "specialist",
    title: "Sports Domain Specialist",
    description: "Specializes in sports data, pick'em games, and the Turf Monster app. Expert in World Cup props and player stats.",
    avatar: "/agents/turf-monster.png",
    position: 1
  },
  {
    name: "Mason",
    slug: "mason",
    status: "active",
    agent_type: "specialist",
    title: "Infrastructure Specialist",
    description: "Handles infrastructure, deployments, monitoring, and system maintenance. Keeps everything running smoothly.",
    avatar: "/agents/mason.png",
    position: 2
  },
  {
    name: "Mack",
    slug: "mack",
    status: "active",
    agent_type: "worker",
    title: "General Worker",
    description: "Versatile worker agent handling data scraping, processing, and general-purpose tasks. Reliable and efficient.",
    avatar: "/agents/mack.png",
    position: 3
  }
]

agents = agents_data.map do |data|
  agent = Agent.find_or_create_by!(slug: data[:slug]) do |a|
    a.name = data[:name]
    a.status = data[:status]
    a.agent_type = data[:agent_type]
    a.title = data[:title]
    a.description = data[:description]
    a.avatar = data[:avatar]
    a.position = data[:position]
  end
  agent.update!(avatar: data[:avatar], position: data[:position]) if agent.avatar != data[:avatar] || agent.position != data[:position]
  puts "Agent: #{agent.name} (#{agent.agent_type})"
  agent
end

# Skills
skills_data = [
  { name: "Web Scraping",        category: "data",           description: "Extract data from websites and APIs" },
  { name: "Data Processing",     category: "data",           description: "Transform, clean, and analyze datasets" },
  { name: "Rails Development",   category: "development",    description: "Build and maintain Ruby on Rails applications" },
  { name: "API Integration",     category: "development",    description: "Connect to and consume external APIs" },
  { name: "Database Management", category: "infrastructure", description: "PostgreSQL administration, migrations, backups" },
  { name: "Deployment",          category: "infrastructure", description: "Deploy applications to production environments" },
  { name: "Monitoring",          category: "system",         description: "System health checks, alerting, and observability" },
  { name: "Task Orchestration",  category: "system",         description: "Coordinate multi-agent workflows and task pipelines" },
  { name: "Sports Analytics",    category: "domain",         description: "Sports data analysis, odds, and prop generation" }
]

skills = skills_data.map do |data|
  skill = Skill.find_or_create_by!(slug: data[:name].parameterize) do |s|
    s.name = data[:name]
    s.category = data[:category]
    s.description = data[:description]
  end
  puts "Skill: #{skill.name} (#{skill.category})"
  skill
end

# Skill Assignments
skill_map = skills.index_by(&:slug)
agent_map = agents.index_by(&:slug)

assignments = {
  "alex"         => ["task-orchestration", "rails-development", "api-integration", "monitoring"],
  "mack"         => ["web-scraping", "data-processing", "api-integration", "database-management"],
  "mason"        => ["deployment", "database-management", "monitoring", "rails-development"],
  "turf-monster" => ["sports-analytics", "data-processing", "rails-development"]
}

assignments.each do |agent_slug, skill_slugs|
  skill_slugs.each do |skill_slug|
    SkillAssignment.find_or_create_by!(agent_slug: agent_slug, skill_slug: skill_slug)
  end
end
puts "Skill assignments created"

# Sample Tasks
tasks_data = [
  { title: "Scrape World Cup 2026 group stage odds",  stage: "done",        priority: 1, agent_slug: "mack",         description: "Pull latest odds from major sportsbooks for all 72 group stage matches." },
  { title: "Deploy Turf Monster v2.1",                 stage: "done",        priority: 2, agent_slug: "mason",        description: "Deploy latest version with long-press button and cart improvements." },
  { title: "Generate player prop lines",               stage: "in_progress", priority: 1, agent_slug: "turf-monster", description: "Calculate over/under lines for 67 seeded players based on historical data." },
  { title: "Set up nightly sync job",                  stage: "queued",      priority: 0, agent_slug: "mason",        description: "Configure cron job for nightly data sync across all agent databases." },
  { title: "Review agent communication protocol",      stage: "new",         priority: 0, agent_slug: "alex",         description: "Audit and improve inter-agent messaging patterns." },
  { title: "Scrape FIFA player injury reports",        stage: "new",         priority: 1, agent_slug: "mack",         description: "Monitor FIFA injury reports and flag affected props." },
  { title: "Archive stale Q1 tasks",                   stage: "archived",    priority: 0, agent_slug: nil,            description: "Clean up completed tasks from Q1 2026." },
  { title: "Fix cart persistence bug on mobile",       stage: "failed",      priority: 2, agent_slug: "turf-monster", description: "Cart picks disappear on mobile Safari after backgrounding the app.",  error_message: "localStorage quota exceeded on iOS Safari private browsing" }
]

tasks_data.each do |data|
  task = Task.find_or_create_by!(title: data[:title]) do |t|
    t.description = data[:description]
    t.stage = data[:stage]
    t.priority = data[:priority]
    t.agent_slug = data[:agent_slug]
    t.error_message = data[:error_message]

    case data[:stage]
    when "queued"      then t.queued_at = 2.hours.ago
    when "in_progress" then t.queued_at = 1.day.ago;  t.started_at = 3.hours.ago
    when "done"        then t.queued_at = 3.days.ago;  t.started_at = 2.days.ago; t.completed_at = 1.day.ago
    when "failed"      then t.queued_at = 2.days.ago;  t.started_at = 1.day.ago;  t.failed_at = 6.hours.ago
    when "archived"    then t.archived_at = 1.week.ago
    end
  end
  puts "Task: #{task.title} (#{task.stage})"
end

# Sample Activities
activities_data = [
  { agent_slug: "mack",         activity_type: "task_completed", description: "Completed scraping World Cup 2026 group stage odds" },
  { agent_slug: "mason",        activity_type: "deployment",     description: "Deployed Turf Monster v2.1 to production" },
  { agent_slug: "turf-monster", activity_type: "task_started",   description: "Started generating player prop lines" },
  { agent_slug: "alex",         activity_type: "task_assigned",  description: "Assigned nightly sync setup to Mason" },
  { agent_slug: "alex",         activity_type: "system_check",   description: "All agents healthy, 4/4 active" },
  { agent_slug: "mack",         activity_type: "data_sync",      description: "Synced 48 team records and 72 game records" }
]

activities_data.each do |data|
  Activity.create!(data) unless Activity.exists?(description: data[:description])
end
puts "Activities created"

# Sample News
news_data = [
  {
    title: "Messi Confirms 2026 World Cup Will Be His Last",
    stage: "concluded",
    url: "https://example.com/messi-last-wc",
    author: "ESPN",
    published_at: 3.days.ago,
    primary_person: "Lionel Messi", primary_team: "Argentina", primary_action: "Retirement Announcement",
    primary_person_slug: "lionel-messi", primary_team_slug: "argentina",
    title_short: "Messi's Last World Cup",
    summary: "Lionel Messi has confirmed that the 2026 World Cup in the US, Mexico and Canada will be his final major tournament.",
    feeling: "bittersweet", feeling_emoji: "🥹", what_happened: "Retirement announcement",
    opinion: "End of an era. This makes every Argentina match must-watch TV. Props on Messi will be massive.",
    callback: "Create 'Messi's Final Act' content series for each Argentina group stage match."
  },
  {
    title: "Pulisic Scores Hat Trick in World Cup Qualifier",
    stage: "refined",
    url: "https://example.com/pulisic-hat-trick",
    author: "Fox Sports",
    published_at: 2.days.ago,
    primary_person: "Christian Pulisic", primary_team: "USA", primary_action: "Goals",
    secondary_person: "Weston McKennie", secondary_team: "Canada",
    primary_person_slug: "christian-pulisic", primary_team_slug: "usa",
    secondary_person_slug: "weston-mckennie", secondary_team_slug: "canada",
    title_short: "Pulisic Hat Trick vs Canada",
    summary: "Christian Pulisic netted three goals as the USMNT cruised past Canada 4-1 in World Cup qualifying.",
    feeling: "hyped", feeling_emoji: "🔥", what_happened: "Hat trick in qualifier"
  },
  {
    title: "Brazil Names Surprise 26-Man Squad",
    stage: "processed",
    url: "https://example.com/brazil-squad",
    author: "BBC Sport",
    published_at: 1.day.ago,
    primary_person: "Endrick", primary_team: "Brazil", primary_action: "Squad Announcement",
    primary_person_slug: "endrick", primary_team_slug: "brazil"
  },
  {
    title: "FIFA Announces World Cup Fan Zone Locations",
    stage: "reviewed",
    author: "FIFA.com",
    published_at: 12.hours.ago,
    primary_team: "FIFA", primary_action: "Event Planning"
  },
  {
    title: "World Cup Draw Reactions: Group of Death Identified",
    stage: "archived",
    url: "https://example.com/draw-reactions",
    author: "The Athletic",
    published_at: 2.weeks.ago,
    primary_team: "FIFA", primary_action: "Draw",
    primary_team_slug: "fifa",
    title_short: "Group of Death Revealed",
    summary: "Group F featuring Germany, Argentina, Nigeria, and Mexico has been dubbed the group of death.",
    feeling: "excited", feeling_emoji: "💀", what_happened: "Group of death identified",
    opinion: "This group is absolute chaos. Every match is a final. Content gold.",
    callback: "Preview series: one article per Group F team."
  },
  # --- 2025 NFL Draft Round 1 — @AdamSchefter (oldest → newest) ---
  *schefter_2025_draft_tweets = [
    { title: "Cam Ward now becomes the fourth No. 1 overall pick that Titans HC Brian Callahan has worked with in his career:\n\n🏈Peyton Manning \n🏈Matthew Stafford\n🏈Joe Burrow\n🏈Cam Ward", x_post_id: "1915559988291940537", published_at: "2025-04-25T00:14:25Z" },
    { title: "ESPN Sources:\n\n🏈Browns are trading the No. 2 overall pick, a fourth-round pick (No. 104), and a sixth-round pick (No. 200) to the Jaguars.\n\n🏈Jaguars are trading the No. 5 overall pick, a second-round pick (No. 36), a fourth-round pick (No. 126) and their 2026 first-round pick", x_post_id: "1915560003773043116", published_at: "2025-04-25T00:14:28Z" },
    { title: "Jaguars are expected to play their first-round draft pick Travis Hunter on offense and defense. They will on-board him by giving him a heavy dose of the wide receiver position while still playing him at his more natural position on defense. Two positions for pick No. 2.", x_post_id: "1915562340382368187", published_at: "2025-04-25T00:23:46Z" },
    { title: "The Giants pick at No. 3:", x_post_id: "1915564627817021689", published_at: "2025-04-25T00:32:51Z" },
    { title: "LSU OT Will Campbell to the Patriots at No. 4 - Drake Maye's new blindside protector.", x_post_id: "1915566069126754663", published_at: "2025-04-25T00:38:35Z" },
    { title: "The projected Patriots offensive line in front of Drake Maye:\n\n🏈LT: Will Campbell \n🏈LG: Cole Strange \n🏈C: Garrett Bradbury \n🏈RG: Mike Onwenu \n🏈RT: Morgan Moses", x_post_id: "1915566391022715263", published_at: "2025-04-25T00:39:51Z" },
    { title: "Browns use the No. 5 overall pick acquired from the Jaguars on Michigan DT Mason Graham.", x_post_id: "1915567622248423471", published_at: "2025-04-25T00:44:45Z" },
    { title: "A new running back for Las Vegas HC Pete Carroll and QB Geno Smith: Raiders select Boise State RB Ashton Jeanty.", x_post_id: "1915568483762659692", published_at: "2025-04-25T00:48:10Z" },
    { title: "Minutes after drafting edge rusher Abdul Carter, Giants GM Joe Schoen said his team is picking up Kayvon Thibodeaux's fifth-year contract option.", x_post_id: "1915569813973590157", published_at: "2025-04-25T00:53:27Z" },
    { title: "Jets HC Aaron Glenn had a 45-minute FaceTime call this week with Missouri OT Armand Membou that sealed New York's decision about who to draft in round one. Membou becomes Glenn's first pick as Jets HC.", x_post_id: "1915570989574004980", published_at: "2025-04-25T00:58:08Z" },
    { title: "Panthers keep the No. 8 pick and instead select WR Tetairoa McMillan.", x_post_id: "1915572398289805700", published_at: "2025-04-25T01:03:44Z" },
    { title: "Saints use No. 9 pick on Texas OT Kelvin Banks Jr.", x_post_id: "1915574020529135875", published_at: "2025-04-25T01:10:10Z" },
    { title: "NFL schedule release will be Wednesday, May 14.", x_post_id: "1915574681337221555", published_at: "2025-04-25T01:12:48Z" },
    { title: "Bears use the No. 10 overall pick to make Michigan's Colston Loveland the first tight end selected in this draft.", x_post_id: "1915576189781000269", published_at: "2025-04-25T01:18:47Z" },
    { title: "49ers use No. 11 overall pick on EDGE Mykel Williams.", x_post_id: "1915578100584157267", published_at: "2025-04-25T01:26:23Z" },
    { title: "Cowboys use No. 12 overall pick on a Zack Martin replacement, Alabama guard Tyler Booker.", x_post_id: "1915578364901122378", published_at: "2025-04-25T01:27:26Z" },
    { title: "DT Kenneth Grant becomes the third Michigan player to go in the first 13 picks, landing with the Dolphins at the No. 13th overall selection.", x_post_id: "1915580392830099761", published_at: "2025-04-25T01:35:30Z" },
    { title: "Colts have looked all over for a tight end in recent seasons and finally find one with the No. 14 overall pick, Penn State's Tyler Warren.", x_post_id: "1915581556531306832", published_at: "2025-04-25T01:40:07Z" },
    { title: "Falcons use No. 15 pick on Georgia DE Jalon Walker.", x_post_id: "1915583486137663960", published_at: "2025-04-25T01:47:47Z" },
    { title: "Cardinals used the No. 16 overall pick on Ole Miss DT Walter Nolen.", x_post_id: "1915584780097253797", published_at: "2025-04-25T01:52:56Z" },
    { title: "Bengals used No. 17 pick on EDGE Shemar Stewart.", x_post_id: "1915586896262004965", published_at: "2025-04-25T02:01:20Z" },
    { title: "Seahawks using No. 18 overall pick on North Dakota State OL Grey Zabel.", x_post_id: "1915587817368961095", published_at: "2025-04-25T02:05:00Z" },
    { title: "Bucs used 19th overall pick on Ohio State WR Emeka Egbuka.", x_post_id: "1915589640255324369", published_at: "2025-04-25T02:12:14Z" },
    { title: "Bucs offense now includes:\n\n🏈QB Baker Mayfield\n🏈RB Bucky Irving\n🏈WR Mike Evans\n🏈WR Chris Godwin\n🏈WR Emeka Egbuka\n🏈WR Jalen McMillan\n🏈TE Cade Otton", x_post_id: "1915589813668823061", published_at: "2025-04-25T02:12:56Z" },
    { title: "Broncos use No. 20 overall pick on Texas CB Jahdae Barron.", x_post_id: "1915591858647978123", published_at: "2025-04-25T02:21:03Z" },
    { title: "Steelers pass on Colorado QB Shedeur Sanders at pick No. 21 and instead select Oregon DT Derrick Harmon.", x_post_id: "1915592661047591413", published_at: "2025-04-25T02:24:15Z" },
    { title: "Chargers HC Jim Harbaugh gets his running back at pick No. 22: North Carolina's Omarion Hampton.", x_post_id: "1915595308282630194", published_at: "2025-04-25T02:34:46Z" },
    { title: "Michigan CB Will Johnson Jr. has a knee issue that has concerned some NFL teams and helps explain why he still has not been selected.", x_post_id: "1915596346637128052", published_at: "2025-04-25T02:38:53Z" },
    { title: "For the first time since 2002 when they drafted Javon Walker, the Green Bay Packers have used a first-round pick on a wide receiver. \n\nAt No. 23, the Packers select Texas WR Matthew Golden.", x_post_id: "1915597927877058751", published_at: "2025-04-25T02:45:10Z" },
    { title: "Giants select Ole Miss QB Jaxson Dart. Another Ole Miss QB like Eli Manning comes to the Giants.", x_post_id: "1915601455689433252", published_at: "2025-04-25T02:59:11Z" },
    { title: "Falcons get:\n🏈2025 1st-round pick (No. 26)\n🏈2025 3rd-round pick\n\nRams get:\n🏈2025 2nd-round pick (No. 46)\n🏈2026 1st-round pick\n🏈2025 7th-round pick", x_post_id: "1915601758123970664", published_at: "2025-04-25T03:00:23Z" },
    { title: "Ravens use No. 27 pick on Georgia S Malaki Starks.", x_post_id: "1915604377156338087", published_at: "2025-04-25T03:10:48Z" },
    { title: "After tonight's trades, the Rams and Browns now own double 1s in the 2026 NFL Draft.", x_post_id: "1915605431667270075", published_at: "2025-04-25T03:14:59Z" },
    { title: "Lions use pick No. 28 on Ohio State DT Tyleik Williams.", x_post_id: "1915605965187014874", published_at: "2025-04-25T03:17:06Z" },
    { title: "Commanders used pick No. 29 on Oregon OT Josh Conerly Jr.", x_post_id: "1915607445340143636", published_at: "2025-04-25T03:22:59Z" },
    { title: "Trade:\n\n🏈Eagles trade No. 32 and No. 164 to the Chiefs\n\n🏈Chiefs trade No. 31 to Eagles.\n\nEagles on the clock.", x_post_id: "1915609101972779048", published_at: "2025-04-25T03:29:34Z" },
    { title: "Eagles are using pick No. 31 on Alabama LB Jihaad Campbell.", x_post_id: "1915611029280641186", published_at: "2025-04-25T03:37:14Z" },
    { title: "With the final first-round pick in the 2025 NFL Draft, the Chiefs selected Ohio State OT Josh Simmons.", x_post_id: "1915612550860886141", published_at: "2025-04-25T03:43:17Z" },
    { title: "Colorado QB Shedeur Sanders did not get selected in Thursday night's first round. \n\nHeading into round two Friday night, as @EpKap notes, there has been only one quarterback drafted in the second round in the last three years combined — Will Levis in 2023.", x_post_id: "1915616051275993423", published_at: "2025-04-25T03:57:11Z" },
  ].reverse.map { |t| t.merge(stage: "new", author: "AdamSchefter", x_post_url: "https://x.com/AdamSchefter/status/#{t[:x_post_id]}") }
]

news_data.each do |data|
  news = News.find_or_create_by!(x_post_id: data[:x_post_id] || data[:title]) do |n|
    n.title = data[:title]
    n.stage = data[:stage]
    n.url = data[:url]
    n.author = data[:author]
    n.published_at = data[:published_at]
    n.x_post_id = data[:x_post_id]
    n.x_post_url = data[:x_post_url]
    n.primary_person = data[:primary_person]
    n.primary_team = data[:primary_team]
    n.primary_action = data[:primary_action]
    n.secondary_person = data[:secondary_person]
    n.secondary_team = data[:secondary_team]
    n.primary_person_slug = data[:primary_person_slug]
    n.primary_team_slug = data[:primary_team_slug]
    n.secondary_person_slug = data[:secondary_person_slug]
    n.secondary_team_slug = data[:secondary_team_slug]
    n.article_image_url = data[:article_image_url]
    n.title_short = data[:title_short]
    n.summary = data[:summary]
    n.feeling = data[:feeling]
    n.feeling_emoji = data[:feeling_emoji]
    n.what_happened = data[:what_happened]
    n.opinion = data[:opinion]
    n.callback = data[:callback]

    case data[:stage]
    when "reviewed"  then n.reviewed_at = 6.hours.ago
    when "processed" then n.reviewed_at = 1.day.ago;   n.processed_at = 12.hours.ago
    when "refined"   then n.reviewed_at = 2.days.ago;   n.processed_at = 1.day.ago;   n.refined_at = 6.hours.ago
    when "concluded" then n.reviewed_at = 3.days.ago;   n.processed_at = 2.days.ago;  n.refined_at = 1.day.ago;   n.concluded_at = 6.hours.ago
    when "archived"  then n.reviewed_at = 2.weeks.ago;  n.processed_at = 2.weeks.ago; n.refined_at = 2.weeks.ago; n.concluded_at = 2.weeks.ago; n.archived_at = 1.week.ago
    end
  end
  puts "News: #{news.title} (#{news.stage})"
end

# Teams (48 World Cup 2026)
TEAMS_DATA = [
  # Group A
  { name: "Mexico", short_name: "MEX", location: "Mexico", emoji: "🇲🇽", color_primary: "#006847", color_secondary: "#CE1126" },
  { name: "South Korea", short_name: "KOR", location: "South Korea", emoji: "🇰🇷", color_primary: "#CD2E3A", color_secondary: "#0047A0" },
  { name: "South Africa", short_name: "RSA", location: "South Africa", emoji: "🇿🇦", color_primary: "#007A4D", color_secondary: "#FFB612" },
  { name: "Czechia", short_name: "CZE", location: "Czechia", emoji: "🇨🇿", color_primary: "#D7141A", color_secondary: "#11457E" },
  # Group B
  { name: "Canada", short_name: "CAN", location: "Canada", emoji: "🇨🇦", color_primary: "#FF0000", color_secondary: "#FFFFFF" },
  { name: "Bosnia and Herzegovina", short_name: "BIH", location: "Bosnia and Herzegovina", emoji: "🇧🇦", color_primary: "#003DA5", color_secondary: "#FCD116" },
  { name: "Qatar", short_name: "QAT", location: "Qatar", emoji: "🇶🇦", color_primary: "#8A1538", color_secondary: "#FFFFFF" },
  { name: "Switzerland", short_name: "SUI", location: "Switzerland", emoji: "🇨🇭", color_primary: "#FF0000", color_secondary: "#FFFFFF" },
  # Group C
  { name: "Brazil", short_name: "BRA", location: "Brazil", emoji: "🇧🇷", color_primary: "#009C3B", color_secondary: "#FFDF00" },
  { name: "Morocco", short_name: "MAR", location: "Morocco", emoji: "🇲🇦", color_primary: "#C1272D", color_secondary: "#006233" },
  { name: "Haiti", short_name: "HAI", location: "Haiti", emoji: "🇭🇹", color_primary: "#00209F", color_secondary: "#D21034" },
  { name: "Scotland", short_name: "SCO", location: "Scotland", emoji: "🏴󠁧󠁢󠁳󠁣󠁴󠁿", color_primary: "#003399", color_secondary: "#FFFFFF" },
  # Group D
  { name: "United States", short_name: "USA", location: "United States", emoji: "🇺🇸", color_primary: "#002868", color_secondary: "#BF0A30" },
  { name: "Paraguay", short_name: "PAR", location: "Paraguay", emoji: "🇵🇾", color_primary: "#D52B1E", color_secondary: "#0038A8" },
  { name: "Australia", short_name: "AUS", location: "Australia", emoji: "🇦🇺", color_primary: "#00843D", color_secondary: "#FFCD00" },
  { name: "Türkiye", short_name: "TUR", location: "Türkiye", emoji: "🇹🇷", color_primary: "#E30A17", color_secondary: "#FFFFFF" },
  # Group E
  { name: "Germany", short_name: "GER", location: "Germany", emoji: "🇩🇪", color_primary: "#000000", color_secondary: "#DD0000" },
  { name: "Curaçao", short_name: "CUW", location: "Curaçao", emoji: "🇨🇼", color_primary: "#003DA5", color_secondary: "#F9E814" },
  { name: "Ivory Coast", short_name: "CIV", location: "Ivory Coast", emoji: "🇨🇮", color_primary: "#FF8200", color_secondary: "#009A44" },
  { name: "Ecuador", short_name: "ECU", location: "Ecuador", emoji: "🇪🇨", color_primary: "#FFD100", color_secondary: "#003DA5", color_text_light: true },
  # Group F
  { name: "Netherlands", short_name: "NED", location: "Netherlands", emoji: "🇳🇱", color_primary: "#FF6600", color_secondary: "#FFFFFF" },
  { name: "Japan", short_name: "JPN", location: "Japan", emoji: "🇯🇵", color_primary: "#000080", color_secondary: "#FFFFFF" },
  { name: "Sweden", short_name: "SWE", location: "Sweden", emoji: "🇸🇪", color_primary: "#006AA7", color_secondary: "#FECC02" },
  { name: "Tunisia", short_name: "TUN", location: "Tunisia", emoji: "🇹🇳", color_primary: "#E70013", color_secondary: "#FFFFFF" },
  # Group G
  { name: "Belgium", short_name: "BEL", location: "Belgium", emoji: "🇧🇪", color_primary: "#ED2939", color_secondary: "#FAE042" },
  { name: "Egypt", short_name: "EGY", location: "Egypt", emoji: "🇪🇬", color_primary: "#CE1126", color_secondary: "#FFFFFF" },
  { name: "Iran", short_name: "IRN", location: "Iran", emoji: "🇮🇷", color_primary: "#239F40", color_secondary: "#DA0000" },
  { name: "New Zealand", short_name: "NZL", location: "New Zealand", emoji: "🇳🇿", color_primary: "#000000", color_secondary: "#FFFFFF" },
  # Group H
  { name: "Spain", short_name: "ESP", location: "Spain", emoji: "🇪🇸", color_primary: "#AA151B", color_secondary: "#F1BF00" },
  { name: "Cape Verde", short_name: "CPV", location: "Cape Verde", emoji: "🇨🇻", color_primary: "#003893", color_secondary: "#CF2028" },
  { name: "Saudi Arabia", short_name: "KSA", location: "Saudi Arabia", emoji: "🇸🇦", color_primary: "#006C35", color_secondary: "#FFFFFF" },
  { name: "Uruguay", short_name: "URU", location: "Uruguay", emoji: "🇺🇾", color_primary: "#5CBFEB", color_secondary: "#FFFFFF", color_text_light: true },
  # Group I
  { name: "France", short_name: "FRA", location: "France", emoji: "🇫🇷", color_primary: "#002395", color_secondary: "#FFFFFF" },
  { name: "Senegal", short_name: "SEN", location: "Senegal", emoji: "🇸🇳", color_primary: "#00853F", color_secondary: "#FDEF42" },
  { name: "Iraq", short_name: "IRQ", location: "Iraq", emoji: "🇮🇶", color_primary: "#007A33", color_secondary: "#FFFFFF" },
  { name: "Norway", short_name: "NOR", location: "Norway", emoji: "🇳🇴", color_primary: "#EF2B2D", color_secondary: "#002868" },
  # Group J
  { name: "Argentina", short_name: "ARG", location: "Argentina", emoji: "🇦🇷", color_primary: "#75AADB", color_secondary: "#FFFFFF", color_text_light: true },
  { name: "Algeria", short_name: "ALG", location: "Algeria", emoji: "🇩🇿", color_primary: "#006633", color_secondary: "#FFFFFF" },
  { name: "Austria", short_name: "AUT", location: "Austria", emoji: "🇦🇹", color_primary: "#ED2939", color_secondary: "#FFFFFF" },
  { name: "Jordan", short_name: "JOR", location: "Jordan", emoji: "🇯🇴", color_primary: "#000000", color_secondary: "#007A3D" },
  # Group K
  { name: "Portugal", short_name: "POR", location: "Portugal", emoji: "🇵🇹", color_primary: "#006600", color_secondary: "#FF0000" },
  { name: "DR Congo", short_name: "COD", location: "DR Congo", emoji: "🇨🇩", color_primary: "#007FFF", color_secondary: "#CE1021" },
  { name: "Uzbekistan", short_name: "UZB", location: "Uzbekistan", emoji: "🇺🇿", color_primary: "#0099CC", color_secondary: "#1EB53A" },
  { name: "Colombia", short_name: "COL", location: "Colombia", emoji: "🇨🇴", color_primary: "#FCD116", color_secondary: "#003893", color_text_light: true },
  # Group L
  { name: "England", short_name: "ENG", location: "England", emoji: "🏴󠁧󠁢󠁥󠁮󠁧󠁿", color_primary: "#FFFFFF", color_secondary: "#CF081F", color_text_light: true },
  { name: "Croatia", short_name: "CRO", location: "Croatia", emoji: "🇭🇷", color_primary: "#FF0000", color_secondary: "#FFFFFF" },
  { name: "Ghana", short_name: "GHA", location: "Ghana", emoji: "🇬🇭", color_primary: "#006B3F", color_secondary: "#FCD116" },
  { name: "Panama", short_name: "PAN", location: "Panama", emoji: "🇵🇦", color_primary: "#DA121A", color_secondary: "#003893" },
]

NFL_TEAMS_DATA = [
  # AFC East
  { name: "Buffalo Bills", short_name: "BUF", location: "Buffalo", emoji: "🦬", color_primary: "#00338D", color_secondary: "#C60C30" },
  { name: "Miami Dolphins", short_name: "MIA", location: "Miami", emoji: "🐬", color_primary: "#008E97", color_secondary: "#FC4C02" },
  { name: "New England Patriots", short_name: "NE", location: "New England", emoji: "🏴", color_primary: "#002244", color_secondary: "#C60C30" },
  { name: "New York Jets", short_name: "NYJ", location: "New York", emoji: "✈️", color_primary: "#125740", color_secondary: "#FFFFFF" },
  # AFC North
  { name: "Baltimore Ravens", short_name: "BAL", location: "Baltimore", emoji: "🐦‍⬛", color_primary: "#241773", color_secondary: "#000000" },
  { name: "Cincinnati Bengals", short_name: "CIN", location: "Cincinnati", emoji: "🐯", color_primary: "#FB4F14", color_secondary: "#000000" },
  { name: "Cleveland Browns", short_name: "CLE", location: "Cleveland", emoji: "🟤", color_primary: "#311D00", color_secondary: "#FF3C00" },
  { name: "Pittsburgh Steelers", short_name: "PIT", location: "Pittsburgh", emoji: "⚙️", color_primary: "#FFB612", color_secondary: "#101820", color_text_light: true },
  # AFC South
  { name: "Houston Texans", short_name: "HOU", location: "Houston", emoji: "🤠", color_primary: "#03202F", color_secondary: "#A71930" },
  { name: "Indianapolis Colts", short_name: "IND", location: "Indianapolis", emoji: "🐴", color_primary: "#002C5F", color_secondary: "#A2AAAD" },
  { name: "Jacksonville Jaguars", short_name: "JAX", location: "Jacksonville", emoji: "🐆", color_primary: "#006778", color_secondary: "#D7A22A" },
  { name: "Tennessee Titans", short_name: "TEN", location: "Tennessee", emoji: "⚔️", color_primary: "#0C2340", color_secondary: "#4B92DB" },
  # AFC West
  { name: "Denver Broncos", short_name: "DEN", location: "Denver", emoji: "🐎", color_primary: "#FB4F14", color_secondary: "#002244" },
  { name: "Kansas City Chiefs", short_name: "KC", location: "Kansas City", emoji: "🏹", color_primary: "#E31837", color_secondary: "#FFB81C" },
  { name: "Las Vegas Raiders", short_name: "LV", location: "Las Vegas", emoji: "☠️", color_primary: "#000000", color_secondary: "#A5ACAF" },
  { name: "Los Angeles Chargers", short_name: "LAC", location: "Los Angeles", emoji: "⚡", color_primary: "#0080C6", color_secondary: "#FFC20E" },
  # NFC East
  { name: "Dallas Cowboys", short_name: "DAL", location: "Dallas", emoji: "⭐", color_primary: "#003594", color_secondary: "#869397" },
  { name: "New York Giants", short_name: "NYG", location: "New York", emoji: "🗽", color_primary: "#0B2265", color_secondary: "#A71930" },
  { name: "Philadelphia Eagles", short_name: "PHI", location: "Philadelphia", emoji: "🦅", color_primary: "#004C54", color_secondary: "#A5ACAF" },
  { name: "Washington Commanders", short_name: "WAS", location: "Washington", emoji: "🎖️", color_primary: "#5A1414", color_secondary: "#FFB612" },
  # NFC North
  { name: "Chicago Bears", short_name: "CHI", location: "Chicago", emoji: "🐻", color_primary: "#0B162A", color_secondary: "#C83803" },
  { name: "Detroit Lions", short_name: "DET", location: "Detroit", emoji: "🦁", color_primary: "#0076B6", color_secondary: "#B0B7BC" },
  { name: "Green Bay Packers", short_name: "GB", location: "Green Bay", emoji: "🧀", color_primary: "#203731", color_secondary: "#FFB612" },
  { name: "Minnesota Vikings", short_name: "MIN", location: "Minnesota", emoji: "⚔️", color_primary: "#4F2683", color_secondary: "#FFC62F" },
  # NFC South
  { name: "Atlanta Falcons", short_name: "ATL", location: "Atlanta", emoji: "🦅", color_primary: "#A71930", color_secondary: "#000000" },
  { name: "Carolina Panthers", short_name: "CAR", location: "Carolina", emoji: "🐆", color_primary: "#0085CA", color_secondary: "#101820" },
  { name: "New Orleans Saints", short_name: "NO", location: "New Orleans", emoji: "⚜️", color_primary: "#D3BC8D", color_secondary: "#101820", color_text_light: true },
  { name: "Tampa Bay Buccaneers", short_name: "TB", location: "Tampa Bay", emoji: "🏴‍☠️", color_primary: "#D50A0A", color_secondary: "#FF7900" },
  # NFC West
  { name: "Arizona Cardinals", short_name: "ARI", location: "Arizona", emoji: "🐦", color_primary: "#97233F", color_secondary: "#000000" },
  { name: "Los Angeles Rams", short_name: "LAR", location: "Los Angeles", emoji: "🐏", color_primary: "#003594", color_secondary: "#FFA300" },
  { name: "San Francisco 49ers", short_name: "SF", location: "San Francisco", emoji: "⛏️", color_primary: "#AA0000", color_secondary: "#B3995D" },
  { name: "Seattle Seahawks", short_name: "SEA", location: "Seattle", emoji: "🦅", color_primary: "#002244", color_secondary: "#69BE28" },
]

ALL_TEAMS = TEAMS_DATA + NFL_TEAMS_DATA

ALL_TEAMS.each do |data|
  team = Team.find_or_create_by!(slug: data[:name].parameterize) do |t|
    t.name = data[:name]
    t.short_name = data[:short_name]
    t.location = data[:location]
    t.emoji = data[:emoji]
    t.color_primary = data[:color_primary]
    t.color_secondary = data[:color_secondary]
    t.color_text_light = data[:color_text_light] || false
  end
  # Update existing records with color_text_light
  team.update!(color_text_light: data[:color_text_light] || false) if team.color_text_light != (data[:color_text_light] || false)
  puts "Team: #{team.emoji} #{team.name} (#{team.short_name})"
end

# Sample Content
contents_data = [
  {
    title: "Messi's Last World Cup — TikTok",
    stage: "posted",
    description: "Lionel Messi has confirmed 2026 will be his last World Cup. Emotional farewell content.",
    source_type: "news",
    content_type: "tiktok_video",
    hook_ideas: ["What if I told you Messi just dropped a bombshell?", "This is the end of an era.", "Messi fans, you need to sit down for this."],
    selected_hook_index: 1,
    script_text: "The GOAT has spoken. Lionel Messi just confirmed that the 2026 World Cup will be his LAST. After winning it all in Qatar, he's going out on his own terms.",
    duration_seconds: 30,
    scenes: [
      { "scene_number" => 1, "description" => "Messi lifting 2022 trophy", "duration_seconds" => 5 },
      { "scene_number" => 2, "description" => "Interview clip with subtitle", "duration_seconds" => 10 },
      { "scene_number" => 3, "description" => "Career highlights montage", "duration_seconds" => 10 },
      { "scene_number" => 4, "description" => "End card with CTA", "duration_seconds" => 5 }
    ],
    platform: "tiktok",
    post_url: "https://tiktok.com/@mcritchie/video/example1",
    post_id: "tiktok_001"
  },
  {
    title: "Pulisic Hat Trick Breakdown",
    stage: "script",
    description: "Christian Pulisic's three goals against Canada — tactical breakdown for TikTok.",
    source_type: "news",
    content_type: "tiktok_video",
    hook_ideas: ["Captain America just went CRAZY", "3 goals. 1 game. 0 mercy.", "Pulisic just silenced every doubter."],
    selected_hook_index: 0,
    script_text: "Captain America just went CRAZY. Three goals against Canada, and each one was more ruthless than the last. Let's break it down.",
    duration_seconds: 45,
    scenes: [
      { "scene_number" => 1, "description" => "Hook with Pulisic celebration", "duration_seconds" => 5 },
      { "scene_number" => 2, "description" => "Goal 1 — positioning analysis", "duration_seconds" => 12 },
      { "scene_number" => 3, "description" => "Goal 2 — first touch breakdown", "duration_seconds" => 12 },
      { "scene_number" => 4, "description" => "Goal 3 — finesse shot", "duration_seconds" => 12 },
      { "scene_number" => 5, "description" => "CTA — follow for more WC content", "duration_seconds" => 4 }
    ]
  },
  {
    title: "World Cup Group of Death Preview",
    stage: "hook",
    description: "Group F is loaded — Germany, Argentina, Nigeria, Mexico. Preview content.",
    source_type: "manual",
    content_type: "tiktok_video",
    hook_ideas: ["This World Cup group is INSANE", "4 teams. Only 2 survive.", "The group of death has been revealed."],
    selected_hook_index: 2
  },
  {
    title: "Top 5 World Cup Sleeper Teams",
    stage: "idea",
    description: "Underdog teams that could make a deep run in 2026. Great hook potential.",
    source_type: "manual",
    content_type: "tiktok_video"
  }
]

# Find the concluded Messi news to link
messi_news = News.find_by(title: "Messi Confirms 2026 World Cup Will Be His Last")

contents_data.each do |data|
  content = Content.find_or_create_by!(title: data[:title]) do |c|
    c.stage = data[:stage]
    c.description = data[:description]
    c.source_type = data[:source_type]
    c.content_type = data[:content_type]
    c.hook_ideas = data[:hook_ideas] || []
    c.selected_hook_index = data[:selected_hook_index]
    c.script_text = data[:script_text]
    c.duration_seconds = data[:duration_seconds]
    c.scenes = data[:scenes] || []
    c.platform = data[:platform]
    c.post_url = data[:post_url]
    c.post_id = data[:post_id]

    # Link to source news if applicable
    if data[:source_type] == "news" && messi_news && data[:title].include?("Messi")
      c.source_news_slug = messi_news.slug
    end

    case data[:stage]
    when "hook"   then c.hooked_at = 6.hours.ago
    when "script" then c.hooked_at = 1.day.ago;   c.scripted_at = 6.hours.ago
    when "posted" then c.hooked_at = 3.days.ago;   c.scripted_at = 2.days.ago; c.asset_at = 1.day.ago; c.assembled_at = 12.hours.ago; c.posted_at = 6.hours.ago
    end
  end
  puts "Content: #{content.title} (#{content.stage})"
end

puts "\nSeed complete!"
