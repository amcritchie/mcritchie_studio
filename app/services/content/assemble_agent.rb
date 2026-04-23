class Content
  class AssembleAgent
    # Kling 3 API — stub endpoint until API docs are provided
    API_URL = ENV.fetch("KLING_API_URL", "https://api.kling.ai/v1/video/generate")

    def self.assemble_latest
      content = Content.where(stage: "assets").order(position: :desc, created_at: :desc).first
      raise "No assets content to assemble" unless content

      new(content).call
    end

    def initialize(content)
      @content = content
      @api_key = ENV["KLING_API_KEY"]
    end

    def call
      raise "KLING_API_KEY not set" if @api_key.blank?
      raise "Content must be in assets stage" unless @content.stage == "assets"

      video_url = generate_video
      Content::Assemble.new(@content).call(
        final_video_url: video_url,
        music_track: nil,
        text_overlays: [],
        logo_overlay: false
      )
      @content
    end

    private

    def generate_video
      scene_assets = @content.scene_assets || []
      return stub_video if scene_assets.empty?

      # Generate motion video from scene image pairs
      # Kling 3 takes adjacent images and generates video transitions
      image_urls = scene_assets.map { |a| a["image_url"] }.compact

      if image_urls.size < 2
        return stub_video
      end

      # Stub — real implementation will:
      # 1. POST image pairs to Kling 3 API
      # 2. Poll for completion (async job)
      # 3. Concatenate resulting video segments
      call_api(image_urls)
    end

    def call_api(image_urls)
      # Stub — returns placeholder until Kling 3 API docs are provided
      puts "  [STUB] Kling 3 video generation from #{image_urls.size} images"
      "https://placeholder.kling.ai/#{SecureRandom.hex(8)}.mp4"
    end

    def stub_video
      puts "  [STUB] No scene assets — generating placeholder video"
      "https://placeholder.kling.ai/#{SecureRandom.hex(8)}.mp4"
    end
  end
end
