require_relative "../../../lib/encoding_sanitizer"

class Content
  class ScriptAgent
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-opus-4-20250514"
    MAX_TOKENS = 2048

    SYSTEM_PROMPT = <<~PROMPT
      You are a short-form sports video scriptwriter. Given a draft pick context (player, team, rival), write a 15-30 second TikTok video script showing the rookie making a highlight play for their new team.

      Key rules:
      - Third-person camera behind the rookie — we see jersey number, last name, build, but NOT face
      - Rookie wears HOME team colors, opponent wears rival team colors
      - First scene = pre-snap or setup, last scene = celebration
      - Keep it cinematic and hype

      Respond with ONLY a JSON object (no markdown, no explanation):
      {
        "script_text": "Full narrative script as one paragraph",
        "duration_seconds": 20,
        "scenes": [
          {
            "number": 1,
            "description": "Scene description",
            "camera": "Camera angle/movement",
            "duration": 5,
            "characters": ["Player Name #99"]
          }
        ]
      }

      Include 3-5 scenes totaling 15-30 seconds.
    PROMPT

    def self.script_latest
      content = Content.where(stage: "hook").order(position: :desc, created_at: :desc).first
      raise "No hook content to script" unless content

      new(content).call
    end

    def initialize(content)
      @content = content
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def call
      raise "ANTHROPIC_API_KEY not set" if @api_key.blank?
      raise "Content must be in hook stage" unless @content.stage == "hook"

      fields = extract_fields
      Content::Script.new(@content).call(fields)
      @content
    end

    private

    def extract_fields
      response = call_api
      text = response.dig("content", 0, "text") || raise("Empty response from Claude API")
      text = text.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "").strip
      parsed = JSON.parse(text)

      {
        script_text: parsed["script_text"],
        duration_seconds: parsed["duration_seconds"],
        scenes: parsed["scenes"] || []
      }
    end

    def build_user_message
      parts = []
      parts << "Title: #{@content.title}"
      parts << "Description: #{@content.description}" if @content.description.present?

      # Player context from source news
      if @content.source_news
        news = @content.source_news
        parts << "Player: #{news.primary_person}" if news.primary_person.present?
        parts << "Team: #{news.primary_team}" if news.primary_team.present?

        # Get athlete appearance if available
        if news.primary_person_slug.present?
          athlete = Athlete.joins(:person).find_by(people: { slug: news.primary_person_slug })
          if athlete
            parts << "Position: #{athlete.position}"
            parts << "Build: #{athlete.build}" if athlete.build.present?
            parts << "Skin tone: #{athlete.skin_tone}" if athlete.skin_tone.present?
            parts << "Hair: #{athlete.hair_description}" if athlete.hair_description.present?
            parts << "Height: #{athlete.height_inches}in" if athlete.height_inches.present?
            parts << "Weight: #{athlete.weight_lbs}lbs" if athlete.weight_lbs.present?
          end
        end

        # Team colors
        if news.primary_team_slug.present?
          team = Team.find_by(slug: news.primary_team_slug)
          if team
            parts << "Home colors: #{team.color_primary} / #{team.color_secondary}"
          end
        end
      end

      # Rival team
      if @content.rival_team
        parts << "Rival team: #{@content.rival_team.name} (#{@content.rival_team.color_primary} / #{@content.rival_team.color_secondary})"
      end

      # Reference video
      if @content.reference_video_url.present?
        ref = "Reference video: #{@content.reference_video_url}"
        ref += " (#{@content.reference_video_start}s - #{@content.reference_video_end}s)" if @content.reference_video_start.present?
        parts << ref
      end

      parts.join("\n")
    end

    def call_api
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["x-api-key"] = @api_key
      request["anthropic-version"] = "2023-06-01"

      request.body = {
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system: SYSTEM_PROMPT,
        messages: [{ role: "user", content: EncodingSanitizer.sanitize_utf8(build_user_message) }]
      }.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Claude API error: #{response.code} — #{response.body}"
      end

      JSON.parse(EncodingSanitizer.sanitize_response_body(response))
    end
  end
end
