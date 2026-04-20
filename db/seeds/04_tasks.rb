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
