# Team metadata overlay (hashtag, hashtag2, x_handle).
#
# Source: db/seeds/data/teams_hashtags.csv (32 NFL teams, matched by short_name).
# Standalone task: bin/rails teams:backfill_metadata
# Idempotent — only sets columns where the CSV has a non-blank value.

Rake::Task["teams:backfill_metadata"].invoke
