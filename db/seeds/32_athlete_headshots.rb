# NFL athlete headshots — links ESPN identity from nflverse, then caches
# resized variants to S3 via Studio::ImageCache.
#
# - Link step (DB-only, ~1s): always runs.
# - Upload step (network + S3, ~25min full): runs only when AWS creds present.
#   Skipped on fresh dev environments without `op run`; ImageCache table
#   stays empty until a manual `bin/rails nfl:upload_headshots`.
#
# Both steps are idempotent. Re-seeding skips athletes that already have
# the espn_id matched and the variants cached.

puts "\n--- NFL headshots ---"

require "rake"
Rails.application.load_tasks unless Rake::Task.task_defined?("nfl:link_headshots")

Rake::Task["nfl:link_headshots"].invoke

if ENV["AWS_ACCESS_KEY_ID"].present?
  Rake::Task["nfl:upload_headshots"].invoke
else
  puts ""
  puts "  ⏭  Skipping S3 upload — AWS_ACCESS_KEY_ID not set."
  puts "     Run later: op run --env-file=/Users/alex/projects/.env -- bin/rails nfl:upload_headshots"
end
