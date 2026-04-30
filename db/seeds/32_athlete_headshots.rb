# Link ESPN identity to Athletes + Coaches.
#
# - Athletes: pull nflverse roster CSV, match by name, set espn_id +
#   espn_headshot_url (always derived from espn_id, never the nflverse
#   headshot_url which is NFL.com 3MB hi-res).
# - Coaches: hit ESPN's /v2/sports/football/leagues/nfl/teams/{id}/coaches
#   per team for HCs (only ~1/3 have a usable headshot.href), then scrape
#   each team's NFL.com /team/coaches[-roster]/ page for HC + 3 coordinators.
#
# DB-only — no S3 traffic. Image upload + caching happens in
# 33_headshot_uploads.rb from the local files committed to the repo.
#
# Idempotent — re-seeds only update rows whose source URL has changed.

puts "\n--- NFL headshot identity links ---"

require "rake"
Rails.application.load_tasks unless Rake::Task.task_defined?("nfl:link_headshots")

Rake::Task["nfl:link_headshots"].invoke
Rake::Task["nfl:link_coach_headshots"].invoke
Rake::Task["nfl:link_coach_headshots_from_team_sites"].invoke
