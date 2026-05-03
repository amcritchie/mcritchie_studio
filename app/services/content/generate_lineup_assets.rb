require "open3"

class Content
  # Capture the lineup-graphic page for a starter_post_x or starter_post_tiktok_*
  # Content, upload PNG + MP4 to S3, save the URLs on the Content, and advance
  # stage to "assets". Dispatches viewport + URL params per workflow:
  #   starter_post_x                  → side=full,    1200×1500, X output dir
  #   starter_post_tiktok_offense     → side=offense, 1080×1920, TikTok output dir
  #   starter_post_tiktok_defense     → side=defense, 1080×1920, TikTok output dir
  class GenerateLineupAssets
    BASE_URL = ENV.fetch("INTERNAL_BASE_URL", "http://localhost:3000")

    SUPPORTED_WORKFLOWS = %w[
      starter_post_x
      starter_post_tiktok_offense
      starter_post_tiktok_defense
    ].freeze

    # Default reveal variant per side; can be overridden via Content#captions
    # tweak in a later iteration. Hike + heat are the recommended defaults.
    DEFAULT_REVEAL = { "offense" => "hike", "defense" => "heat" }.freeze
    DEFAULT_PACE   = { "offense" => 1500,   "defense" => 1700 }.freeze

    def initialize(content)
      @content = content
    end

    def call
      raise "wrong workflow: #{@content.workflow}" unless SUPPORTED_WORKFLOWS.include?(@content.workflow)
      raise "team_slug missing" if @content.team_slug.blank?

      out_dir = Rails.root.join("tmp", "lineup-graphics")
      FileUtils.mkdir_p(out_dir)

      side       = @content.lineup_side    # nil for starter_post_x, "offense" or "defense" for tiktok
      base_name  = side ? "#{@content.team_slug}-#{side}" : @content.team_slug
      png_path   = out_dir.join("#{base_name}.png")
      frames_dir = out_dir.join("#{base_name}-frames")
      mp4_path   = out_dir.join("#{base_name}.mp4")

      capture!(side: side)

      raise "capture produced no PNG (#{png_path})" unless File.exist?(png_path)
      raise "no frames captured in #{frames_dir}" if Dir.glob(frames_dir.join("frame_*.png")).empty?

      LineupGraphic::AssembleVideo.call(
        frames_dir: frames_dir,
        output_mp4: mp4_path,
        side:       (side || "full").to_sym
      )

      png_url = upload(png_path, key_for("png", side), "image/png")
      mp4_url = File.exist?(mp4_path) ? upload(mp4_path, key_for("mp4", side), "video/mp4") : nil

      @content.update!(
        hook_image_url:  png_url,
        final_video_url: mp4_url,
        stage: "assets"
      )
      @content
    end

    private

    def capture!(side:)
      env = {}
      if side
        env["SIDE"]   = side
        env["REVEAL"] = DEFAULT_REVEAL[side]
        env["PACE"]   = DEFAULT_PACE[side].to_s
      end
      cmd = ["node", "script/capture_lineup.js", @content.team_slug, BASE_URL]
      out, status = Open3.capture2e(env, *cmd, chdir: Rails.root.to_s)
      raise "capture failed (#{status.exitstatus}):\n#{out}" unless status.success?
    end

    def upload(path, key, content_type)
      Studio::S3.upload(
        key: key,
        body: File.read(path),
        content_type: content_type,
        cache_control: "public, max-age=31536000, immutable"
      )
    end

    def key_for(ext, side)
      if side
        "tiktok_posts/#{@content.team_slug}/#{@content.slug}_#{side}.#{ext}"
      else
        "starter_posts/#{@content.team_slug}/#{@content.slug}.#{ext}"
      end
    end
  end
end
