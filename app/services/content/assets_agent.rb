class Content
  class AssetsAgent
    # Nano Banana API — stub endpoint until API docs are provided
    API_URL = ENV.fetch("NANO_BANANA_API_URL", "https://api.nanobanana.com/v1/generate")

    def self.assets_latest
      content = Content.where(stage: "script").order(position: :desc, created_at: :desc).first
      raise "No script content to generate assets" unless content

      new(content).call
    end

    def initialize(content)
      @content = content
      @api_key = ENV["NANO_BANANA_API_KEY"]
    end

    def call
      raise "NANO_BANANA_API_KEY not set" if @api_key.blank?
      raise "Content must be in script stage" unless @content.stage == "script"

      scene_assets = generate_scene_assets
      Content::Assets.new(@content).call(scene_assets: scene_assets)
      @content
    end

    private

    def generate_scene_assets
      scenes = @content.scenes || []
      # Select 2-5 key scenes for image generation
      key_scenes = scenes.first(5)

      key_scenes.map do |scene|
        prompt = build_image_prompt(scene)
        image_url = call_api(prompt)

        {
          "scene_number" => scene["number"],
          "prompt_used" => prompt,
          "image_url" => image_url
        }
      end
    end

    def build_image_prompt(scene)
      parts = []
      parts << "Cinematic sports photograph, third-person camera behind player"
      parts << scene["description"] if scene["description"]
      parts << "Camera: #{scene["camera"]}" if scene["camera"]

      # Player appearance
      if @content.source_news&.primary_person_slug
        athlete = Athlete.joins(:person).find_by(people: { slug: @content.source_news.primary_person_slug })
        if athlete
          parts << "Player build: #{athlete.build}" if athlete.build.present?
          parts << "Player skin tone: #{athlete.skin_tone}" if athlete.skin_tone.present?
          parts << "Player hair: #{athlete.hair_description}" if athlete.hair_description.present?
        end
      end

      # Team uniforms
      if @content.source_news&.primary_team_slug
        team = Team.find_by(slug: @content.source_news.primary_team_slug)
        parts << "Home uniform colors: #{team.color_primary}/#{team.color_secondary}" if team
      end

      if @content.rival_team
        parts << "Opponent uniform colors: #{@content.rival_team.color_primary}/#{@content.rival_team.color_secondary}"
      end

      parts.join(". ")
    end

    def call_api(prompt)
      # Stub — returns placeholder until Nano Banana API docs are provided
      # Real implementation will POST to API_URL with prompt and API key
      puts "  [STUB] Nano Banana image generation: #{prompt.truncate(100)}"
      "https://placeholder.nanobanana.com/#{SecureRandom.hex(8)}.png"
    end
  end
end
