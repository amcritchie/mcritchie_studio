namespace :content do
  desc "Run hook stage on next idea content (or SLUG=content-xxx)"
  task hook: :environment do
    content = if ENV["SLUG"]
      Content.find_by!(slug: ENV["SLUG"])
    else
      Content.where(stage: "idea").order(position: :desc, created_at: :desc).first
    end
    raise "No idea content to hook" unless content

    Content::Hook.new(content).call(
      hook_image_url: ENV["HOOK_IMAGE_URL"],
      hook_ideas: ENV["HOOK_IDEAS"]&.split("|") || [],
      selected_hook_index: ENV["SELECTED_HOOK"]&.to_i
    )

    puts "Hooked: #{content.title.truncate(80)} (#{content.slug})"
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "Run script stage on next hook content (or SLUG=content-xxx)"
  task script: :environment do
    content = if ENV["SLUG"]
      Content.find_by!(slug: ENV["SLUG"])
    else
      Content.where(stage: "hook").order(position: :desc, created_at: :desc).first
    end
    raise "No hook content to script" unless content

    Content::Script.new(content).call(
      script_text: ENV["SCRIPT_TEXT"] || "Script placeholder",
      duration_seconds: ENV["DURATION"]&.to_i || 30,
      scenes: []
    )

    puts "Scripted: #{content.title.truncate(80)} (#{content.slug})"
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "Run assets stage on next script content (or SLUG=content-xxx)"
  task assets: :environment do
    content = if ENV["SLUG"]
      Content.find_by!(slug: ENV["SLUG"])
    else
      Content.where(stage: "script").order(position: :desc, created_at: :desc).first
    end
    raise "No script content to generate assets" unless content

    Content::Assets.new(content).call(scene_assets: [])

    puts "Assets: #{content.title.truncate(80)} (#{content.slug})"
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "Run assemble stage on next assets content (or SLUG=content-xxx)"
  task assemble: :environment do
    content = if ENV["SLUG"]
      Content.find_by!(slug: ENV["SLUG"])
    else
      Content.where(stage: "assets").order(position: :desc, created_at: :desc).first
    end
    raise "No assets content to assemble" unless content

    Content::Assemble.new(content).call(
      final_video_url: ENV["VIDEO_URL"] || "placeholder.mp4",
      music_track: ENV["MUSIC_TRACK"],
      text_overlays: [],
      logo_overlay: true
    )

    puts "Assembled: #{content.title.truncate(80)} (#{content.slug})"
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "Run post stage on next assembly content (or SLUG=content-xxx)"
  task post: :environment do
    content = if ENV["SLUG"]
      Content.find_by!(slug: ENV["SLUG"])
    else
      Content.where(stage: "assembly").order(position: :desc, created_at: :desc).first
    end
    raise "No assembly content to post" unless content

    Content::Post.new(content).call(
      platform: ENV["PLATFORM"] || "tiktok",
      post_url: ENV["POST_URL"],
      post_id: ENV["POST_ID"]
    )

    puts "Posted: #{content.title.truncate(80)} (#{content.slug})"
    puts "  URL: #{content.post_url}" if content.post_url.present?
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "Run review stage on next posted content (or SLUG=content-xxx)"
  task review: :environment do
    content = if ENV["SLUG"]
      Content.find_by!(slug: ENV["SLUG"])
    else
      Content.where(stage: "posted").order(position: :desc, created_at: :desc).first
    end
    raise "No posted content to review" unless content

    Content::Review.new(content).call(
      views: ENV["VIEWS"]&.to_i,
      likes: ENV["LIKES"]&.to_i,
      comments_count: ENV["COMMENTS"]&.to_i,
      shares: ENV["SHARES"]&.to_i,
      review_notes: ENV["NOTES"]
    )

    puts "Reviewed: #{content.title.truncate(80)} (#{content.slug})"
    puts "  Views: #{content.views}, Likes: #{content.likes}"
    puts "Done — stage is now '#{content.stage}'"
  end
end
