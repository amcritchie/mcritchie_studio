# Upload headshot originals from local repo files + generate cached variants.
#
# Reads db/seeds/data/headshots/nfl/{team}/{person}.{ext} for athletes and
# db/seeds/data/headshots/nfl/coaches/{coach.slug}.{ext} for coaches. For
# each file, calls Studio::ImageCache.cache! which uploads original + 100w +
# 400w to S3 and creates one ImageCache row per variant.
#
# Source of truth: the local files. The seed never hits ESPN/NFL.com — those
# remain available via lib/tasks/nfl.rake (link_*) for discovering new
# players/coaches not yet in the bundled set.
#
# Idempotent: variants already cached are skipped. First seed (~1,680 originals)
# takes ~10 min; re-seeds finish in seconds.
#
# Skipped entirely when AWS_ACCESS_KEY_ID is unset OR the local data dir is
# empty (e.g. fresh clone before `git lfs pull`).

puts "\n--- NFL headshot uploads (from local files) ---"

local_root = Rails.root.join("db/seeds/data/headshots/nfl")

unless ENV["AWS_ACCESS_KEY_ID"].present?
  puts "  ⏭  Skipping — AWS_ACCESS_KEY_ID not set."
  puts "     Run later: op run --env-file=/Users/alex/projects/.env -- bin/rails db:seed"
  return
end

unless Dir.exist?(local_root) && Dir.glob(local_root.join("**/*.{png,jpg}")).any?
  puts "  ⏭  Skipping — no local files at #{local_root}"
  puts "     Run `git lfs pull` to fetch headshot originals."
  return
end

cached           = 0
skipped_complete = 0
skipped_no_owner = 0
failed           = 0

Dir.glob(local_root.join("**/*.{png,jpg}")).each do |path|
  rel   = Pathname.new(path).relative_path_from(local_root)
  parts = rel.to_s.split("/")
  ext   = File.extname(parts.last)
  content_type = ext == ".png" ? "image/png" : "image/jpeg"

  if parts.first == "coaches"
    slug       = File.basename(parts.last, ext)
    owner      = Coach.find_by(slug: slug)
    key_prefix = "headshots/nfl/coaches/#{slug}"
  else
    team_slug   = parts[0]
    person_slug = File.basename(parts.last, ext)
    owner       = Person.find_by(slug: person_slug)&.athlete_profile
    key_prefix  = "headshots/nfl/#{team_slug}/#{person_slug}"
  end

  unless owner
    skipped_no_owner += 1
    next
  end

  have = owner.image_caches.where(purpose: "headshot").pluck(:variant)
  if (%w[original 100 400] - have).empty?
    skipped_complete += 1
    next
  end

  begin
    Studio::ImageCache.cache!(
      owner: owner,
      purpose: "headshot",
      source_path: path,
      source_url: owner.try(:espn_headshot_url),
      key_prefix: key_prefix,
      widths: [100, 400],
      content_type: content_type
    )
    cached += 1
    puts "  [+] #{key_prefix}" if cached <= 3 || (cached % 200).zero?
  rescue => e
    failed += 1
    puts "  [!] #{path}: #{e.class}: #{e.message}"
  end
end

puts ""
puts "cached:                 #{cached}"
puts "skipped (already done): #{skipped_complete}"
puts "skipped (no owner):     #{skipped_no_owner}"
puts "failed:                 #{failed}"
