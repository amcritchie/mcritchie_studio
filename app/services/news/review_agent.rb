require_relative "../../../lib/encoding_sanitizer"

class News
  class ReviewAgent
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-haiku-4-5-20251001"
    MAX_TOKENS = 512

    SYSTEM_PROMPT = <<~PROMPT
      You are a sports news analyst. Given a tweet or news headline, extract structured information about the people and teams involved.

      Respond with ONLY a JSON object (no markdown, no explanation) with these fields:
      - primary_person: The main person the news is about (full name). Null if no specific person.
      - primary_team: The main team involved (full official name). Null if no specific team.
      - primary_action: A one-word or short verb/phrase describing what happened (e.g. "traded", "extended", "injured", "signed", "fired", "suspended", "retired").
      - secondary_person: A second person involved, if any. Null otherwise.
      - secondary_team: A second team involved, if any (e.g. the team they were traded to). Null otherwise.

      Examples:
      Tweet: "Breaking: Patrick Mahomes has agreed to a 10-year extension with the Kansas City Chiefs worth $450M"
      {"primary_person":"Patrick Mahomes","primary_team":"Kansas City Chiefs","primary_action":"extended","secondary_person":null,"secondary_team":null}

      Tweet: "Sources: The Dallas Cowboys are trading Dak Prescott to the San Francisco 49ers for two first-round picks"
      {"primary_person":"Dak Prescott","primary_team":"Dallas Cowboys","primary_action":"traded","secondary_person":null,"secondary_team":"San Francisco 49ers"}
    PROMPT

    def self.review_latest
      news = News.where(stage: "new").order(position: :desc, created_at: :desc).first
      raise "No new articles to review" unless news

      new(news).call
    end

    def initialize(news)
      @news = news
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def call
      raise "ANTHROPIC_API_KEY not set" if @api_key.blank?
      raise "News must be in new stage" unless @news.stage == "new"

      fields = extract_fields
      News::Review.new(@news).call(fields)
      @news
    end

    private

    def extract_fields
      response = call_api
      text = response.dig("content", 0, "text") || raise("Empty response from Claude API")
      text = text.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "").strip
      parsed = JSON.parse(text)

      {
        primary_person: parsed["primary_person"],
        primary_team: parsed["primary_team"],
        primary_action: parsed["primary_action"],
        secondary_person: parsed["secondary_person"],
        secondary_team: parsed["secondary_team"],
        article_image_url: nil
      }
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
        messages: [{ role: "user", content: EncodingSanitizer.sanitize_utf8(@news.title) }]
      }.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Claude API error: #{response.code} — #{response.body}"
      end

      JSON.parse(EncodingSanitizer.sanitize_response_body(response))
    end
  end
end
