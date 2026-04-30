# NFL athlete + head-coach headshots — links ESPN identity, then caches
# resized variants to S3 via Studio::ImageCache.
#
# - Link steps (DB-only, ~1s each): always run. Pull from nflverse roster CSV
#   for athletes; from ESPN's per-team coaches API for head coaches.
# - Upload steps (network + S3, ~25min full athletes / seconds for coaches):
#   only run when AWS creds present. Skipped on fresh dev environments
#   without `op run`; ImageCache table stays empty until manual upload.
#
# Coaches: ESPN only exposes head coaches via the public API, and only ~1/3
# of them have a `headshot.href` field set. Coordinators are not available.
#
# All steps are idempotent — re-seeding skips already-linked + already-cached.

puts "\n--- NFL headshots ---"

require "rake"
Rails.application.load_tasks unless Rake::Task.task_defined?("nfl:link_headshots")

Rake::Task["nfl:link_headshots"].invoke
Rake::Task["nfl:link_coach_headshots"].invoke

if ENV["AWS_ACCESS_KEY_ID"].present?
  Rake::Task["nfl:upload_headshots"].invoke
  Rake::Task["nfl:upload_coach_headshots"].invoke
else
  puts ""
  puts "  ⏭  Skipping S3 upload — AWS_ACCESS_KEY_ID not set."
  puts "     Run later: op run --env-file=/Users/alex/projects/.env -- bin/rails nfl:upload_headshots nfl:upload_coach_headshots"
end
