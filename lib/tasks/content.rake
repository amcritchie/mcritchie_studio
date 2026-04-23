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

  # --- AI Agent Tasks ---

  desc "AI-generate script from hook content (Claude Opus) — SLUG=content-xxx"
  task script_agent: :environment do
    content = if ENV["SLUG"]
      Content::ScriptAgent.new(Content.find_by!(slug: ENV["SLUG"])).call
    else
      Content::ScriptAgent.script_latest
    end

    puts "Script generated: #{content.title.truncate(80)} (#{content.slug})"
    puts "  Duration: #{content.duration_seconds}s"
    puts "  Scenes: #{content.scenes&.size || 0}"
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "AI-generate scene images (Nano Banana) — SLUG=content-xxx"
  task assets_agent: :environment do
    content = if ENV["SLUG"]
      Content::AssetsAgent.new(Content.find_by!(slug: ENV["SLUG"])).call
    else
      Content::AssetsAgent.assets_latest
    end

    puts "Assets generated: #{content.title.truncate(80)} (#{content.slug})"
    puts "  Scene assets: #{content.scene_assets&.size || 0}"
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "AI-assemble video from images (Kling 3) — SLUG=content-xxx"
  task assemble_agent: :environment do
    content = if ENV["SLUG"]
      Content::AssembleAgent.new(Content.find_by!(slug: ENV["SLUG"])).call
    else
      Content::AssembleAgent.assemble_latest
    end

    puts "Video assembled: #{content.title.truncate(80)} (#{content.slug})"
    puts "  Video URL: #{content.final_video_url}"
    puts "Done — stage is now '#{content.stage}'"
  end

  desc "Apply watermark to assembled video (FFmpeg) — SLUG=content-xxx"
  task finalize: :environment do
    content = if ENV["SLUG"]
      Content::Finalize.new(Content.find_by!(slug: ENV["SLUG"])).call
    else
      Content::Finalize.finalize_latest
    end

    puts "Finalized: #{content.title.truncate(80)} (#{content.slug})"
    puts "  Video URL: #{content.final_video_url}"
    puts "  Watermark: #{content.logo_overlay ? 'yes' : 'no'}"
  end

  desc "AI-generate TikTok metadata (Claude Haiku) — SLUG=content-xxx"
  task metadata: :environment do
    content = if ENV["SLUG"]
      Content::MetadataAgent.new(Content.find_by!(slug: ENV["SLUG"])).call
    else
      Content::MetadataAgent.metadata_latest
    end

    puts "Metadata generated: #{content.title.truncate(80)} (#{content.slug})"
    puts "  Caption: #{content.captions&.truncate(100)}"
    puts "  Hashtags: #{content.hashtags&.size || 0}"
    puts "  Music: #{content.music_suggestions&.size || 0}"
  end

  desc "Run full AI pipeline on one content item — SLUG=content-xxx"
  task generate: :environment do
    slug = ENV["SLUG"]
    raise "SLUG= required for content:generate" unless slug

    content = Content.find_by!(slug: slug)
    puts "Starting full pipeline: #{content.title.truncate(80)} (#{content.slug})"
    puts "  Current stage: #{content.stage}"

    if content.stage == "hook"
      puts "\n--- Script Agent (Claude Opus) ---"
      Content::ScriptAgent.new(content).call
      content.reload
      puts "  Stage: #{content.stage}, Duration: #{content.duration_seconds}s, Scenes: #{content.scenes&.size}"
    end

    if content.stage == "script"
      puts "\n--- Assets Agent (Nano Banana) ---"
      Content::AssetsAgent.new(content).call
      content.reload
      puts "  Stage: #{content.stage}, Assets: #{content.scene_assets&.size}"
    end

    if content.stage == "assets"
      puts "\n--- Assemble Agent (Kling 3) ---"
      Content::AssembleAgent.new(content).call
      content.reload
      puts "  Stage: #{content.stage}, Video: #{content.final_video_url}"
    end

    if content.stage == "assembly"
      puts "\n--- Finalize (FFmpeg) ---"
      Content::Finalize.new(content).call
      content.reload
      puts "  Stage: #{content.stage}, Watermark: #{content.logo_overlay}"
    end

    puts "\n--- Metadata Agent (Claude Haiku) ---"
    Content::MetadataAgent.new(content).call
    content.reload
    puts "  Caption: #{content.captions&.truncate(80)}"
    puts "  Hashtags: #{content.hashtags&.join(', ')}"

    puts "\nPipeline complete! Final stage: #{content.stage}"
  end
end
