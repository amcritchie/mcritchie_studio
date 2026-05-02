require "open3"

class Content
  # Capture the lineup-graphic page for a starter_post_x Content,
  # upload the PNG + MP4 to S3, save the URLs on the Content, and
  # advance the stage to "assets".
  class GenerateLineupAssets
    BASE_URL = ENV.fetch("INTERNAL_BASE_URL", "http://localhost:3000")

    def initialize(content)
      @content = content
    end

    def call
      raise "wrong workflow: #{@content.workflow}" unless @content.workflow == "starter_post_x"
      raise "team_slug missing" if @content.team_slug.blank?

      out_dir = Rails.root.join("tmp", "lineup-graphics")
      FileUtils.mkdir_p(out_dir)

      capture!
      png_path    = out_dir.join("#{@content.team_slug}.png")
      frames_dir  = out_dir.join("#{@content.team_slug}-frames")
      mp4_path    = out_dir.join("#{@content.team_slug}.mp4")

      raise "capture produced no PNG (#{png_path})" unless File.exist?(png_path)
      raise "no frames captured in #{frames_dir}" if Dir.glob(frames_dir.join("frame_*.png")).empty?

      LineupGraphic::AssembleVideo.call(frames_dir: frames_dir, output_mp4: mp4_path)

      png_url = upload(png_path, key_for("png"), "image/png")
      mp4_url = File.exist?(mp4_path) ? upload(mp4_path, key_for("mp4"), "video/mp4") : nil

      @content.update!(
        hook_image_url:  png_url,
        final_video_url: mp4_url,
        stage: "assets"
      )
      @content
    end

    private

    def capture!
      cmd = ["node", "script/capture_lineup.js", @content.team_slug, BASE_URL]
      out, status = Open3.capture2e(*cmd, chdir: Rails.root.to_s)
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

    def key_for(ext)
      "starter_posts/#{@content.team_slug}/#{@content.slug}.#{ext}"
    end
  end
end
