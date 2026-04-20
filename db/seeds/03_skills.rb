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

skills_data.each do |data|
  skill = Skill.find_or_create_by!(slug: data[:name].parameterize) do |s|
    s.name = data[:name]
    s.category = data[:category]
    s.description = data[:description]
  end
  puts "Skill: #{skill.name} (#{skill.category})"
end

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
