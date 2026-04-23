require_relative "../../../lib/encoding_sanitizer"

class Content
  class MetadataAgent
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-haiku-4-5-20251001"
    MAX_TOKENS = 512

    SYSTEM_PROMPT = <<~PROMPT
      You are a TikTok content strategist for sports content. Generate metadata for a short-form video about an NFL draft pick making a highlight play.

      Respond with ONLY a JSON object (no markdown, no explanation):
      {
        "captions": "TikTok caption text (1-2 sentences, engaging, with emojis)",
        "hashtags": ["hashtag1", "hashtag2", ...],
        "music_suggestions": ["Track Name - Artist", ...]
      }

      Rules:
      - Caption should be engaging and create urgency/excitement
      - Include 8-12 relevant hashtags (mix of broad like #NFL #NFLDraft and specific like team/player names)
      - Suggest 3 trending/hype music tracks that fit football highlight content
      - Do NOT include # in hashtag strings (just the word)
    PROMPT

    def self.metadata_latest
      content = Content.order(position: :desc, created_at: :desc).first
      raise "No content for metadata" unless content

      new(content).call
    end

    def initialize(content)
      @content = content
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def call
      raise "ANTHROPIC_API_KEY not set" if @api_key.blank?

      fields = extract_fields
      @content.update!(
        captions: fields[:captions],
        hashtags: fields[:hashtags] || [],
        music_suggestions: fields[:music_suggestions] || []
      )
      @content
    end

    private

    def extract_fields
      response = call_api
      text = response.dig("content", 0, "text") || raise("Empty response from Claude API")
      text = text.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "").strip
      parsed = JSON.parse(text)

      {
        captions: parsed["captions"],
        hashtags: parsed["hashtags"],
        music_suggestions: parsed["music_suggestions"]
      }
    end

    def build_user_message
      parts = []
      parts << "Title: #{@content.title}"
      parts << "Description: #{@content.description}" if @content.description.present?
      parts << "Script: #{@content.script_text.truncate(500)}" if @content.script_text.present?

      if @content.source_news
        news = @content.source_news
        parts << "Player: #{news.primary_person}" if news.primary_person.present?
        parts << "Team: #{news.primary_team}" if news.primary_team.present?
        parts << "Summary: #{news.summary.truncate(200)}" if news.summary.present?
      end

      if @content.rival_team
        parts << "Rival: #{@content.rival_team.name}"
      end

      parts.join("\n")
    end

    def call_api
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

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
