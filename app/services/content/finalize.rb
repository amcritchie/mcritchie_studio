class Content
  class Finalize
    WATERMARK_PATH = Rails.root.join("public", "studio-logo.svg").to_s

    def self.finalize_latest
      content = Content.where(stage: "assembly").order(position: :desc, created_at: :desc).first
      raise "No assembly content to finalize" unless content

      new(content).call
    end

    def initialize(content)
      @content = content
    end

    def call
      raise "Content must be in assembly stage" unless @content.stage == "assembly"
      raise "No final_video_url to watermark" if @content.final_video_url.blank?

      # Stub — full FFmpeg integration TBD based on Heroku buildpack availability
      # Real implementation will:
      # 1. Download video from final_video_url
      # 2. Apply watermark overlay via FFmpeg
      # 3. Upload watermarked video
      # 4. Update final_video_url with watermarked version
      watermarked_url = apply_watermark(@content.final_video_url)

      @content.update!(
        final_video_url: watermarked_url,
        logo_overlay: true
      )
      @content
    end

    private

    def apply_watermark(video_url)
      # Stub — returns same URL with watermark flag
      puts "  [STUB] FFmpeg watermark overlay on #{video_url.truncate(60)}"
      puts "  [STUB] Watermark source: #{WATERMARK_PATH}"
      video_url
    end
  end
end
