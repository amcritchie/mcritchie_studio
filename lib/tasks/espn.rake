namespace :espn do
  desc "Scrape ESPN per-team depth charts and apply to DepthChart. TEAM=buf for one team. VERBOSE=1 for full match logs."
  task scrape_depth_charts: :environment do
    Espn::ScrapeDepthCharts.new(team_abbrev: ENV["TEAM"], verbose: ENV["VERBOSE"].present?).call
  end
end
