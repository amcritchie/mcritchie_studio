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
    u.password = "pass"
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

# Payment Methods
admin_user = User.find_by(email: "alex@mcritchie.studio")
payment_methods_data = [
  { name: "Robinhood Gold",    slug: nil,     last_four: "9349", parser_key: "robinhood",         color: "#F8D180", color_secondary: nil, logo: "/payment_methods/robinhood.png",           position: 100 },
  { name: "Capital One Spark", slug: "spark", last_four: "5179", parser_key: "capital_one_spark", color: "#2F6D45", color_secondary: nil, logo: "/payment_methods/capital-one-spark.png", position: 200 },
  { name: "Capital One Savor", slug: "savor", last_four: "7867", parser_key: "capital_one_spark", color: "#9B503A", color_secondary: nil, logo: "/payment_methods/capital-one.png",       position: 300 },
  { name: "Chase Ink",         slug: nil,     last_four: "8895", parser_key: nil,                 color: "#72777D", color_secondary: nil, logo: "/payment_methods/chase.png",              position: 400 },
  { name: "Citi Double Cash",  slug: nil,     last_four: "5578", parser_key: "citi",              color: "#4794C8", color_secondary: nil, logo: "/payment_methods/citi.png",               position: 500 }
]

payment_methods_data.each do |data|
  pm = PaymentMethod.find_or_create_by!(name: data[:name]) do |p|
    p.user = admin_user
    p.last_four = data[:last_four]
    p.parser_key = data[:parser_key]
    p.color = data[:color]
    p.logo = data[:logo]
    p.position = data[:position]
  end
  pm.update!(color: data[:color], color_secondary: data[:color_secondary], logo: data[:logo], position: data[:position]) if pm.color != data[:color] || pm.color_secondary != data[:color_secondary] || pm.logo != data[:logo] || pm.position != data[:position]
  pm.update_column(:slug, data[:slug]) if data[:slug].present? && pm.slug != data[:slug]
  puts "PaymentMethod: #{pm.name} [#{pm.slug}] (#{pm.status})"
end

# Backfill existing uploads with payment methods
ExpenseUpload.where(payment_method_id: nil).where.not(card_type: [nil, ""]).find_each do |upload|
  pm = PaymentMethod.find_by(parser_key: upload.card_type)
  upload.update_column(:payment_method_id, pm.id) if pm
end
puts "Backfilled existing uploads"

puts "\nSeed complete!"
