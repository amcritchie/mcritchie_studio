class News
  class RefineAgent
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-haiku-4-5-20251001"
    MAX_TOKENS = 512

    SYSTEM_PROMPT = <<~PROMPT
      You are a sports news editor. Given a tweet/headline and context about the people and teams involved, generate a refined summary.

      Respond with ONLY a JSON object (no markdown, no explanation) with these fields:
      - title_short: A factual headline of exactly 3-5 words built from the PRIMARY person (or team) and the action. Format: "[Person/Team] [Action verb] [Object]". Focus on the raw event, not secondary context. Examples: "Mahomes Signs Record Extension", "Ward Drafted By Titans", "Messi Retires From Argentina".
      - summary: A 1-3 sentence summary of what happened and why it matters.
      - feeling: A single word describing the emotional tone (e.g. "excited", "concerned", "shocked", "hopeful", "bittersweet").
      - feeling_emoji: A single emoji that captures the feeling.
      - what_happened: A brief factual description of the event in one sentence.

      Examples:
      Tweet: "Breaking: Patrick Mahomes has agreed to a 10-year extension with the Kansas City Chiefs worth $450M"
      Context: Person=Patrick Mahomes, Team=Kansas City Chiefs, Action=extended
      {"title_short":"Mahomes Signs Record Extension","summary":"Patrick Mahomes has locked in with the Kansas City Chiefs on a historic 10-year, $450 million extension, the richest deal in NFL history. The deal makes him the highest-paid player in NFL history.","feeling":"hyped","feeling_emoji":"🔥","what_happened":"Patrick Mahomes agreed to a 10-year, $450M contract extension with the Chiefs."}
    PROMPT

    def self.refine_latest
      news = News.where(stage: "processed").order(position: :desc, created_at: :desc).first
      raise "No processed articles to refine" unless news

      new(news).call
    end

    def initialize(news)
      @news = news
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def call
      raise "ANTHROPIC_API_KEY not set" if @api_key.blank?
      raise "News must be in processed stage" unless @news.stage == "processed"

      fields = extract_fields
      News::Refine.new(@news).call(fields)
      @news
    end

    private

    def extract_fields
      response = call_api
      text = response.dig("content", 0, "text") || raise("Empty response from Claude API")
      text = text.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "").strip
      parsed = JSON.parse(text)

      {
        title_short: parsed["title_short"],
        summary: parsed["summary"],
        feeling: parsed["feeling"],
        feeling_emoji: parsed["feeling_emoji"],
        what_happened: parsed["what_happened"]
      }
    end

    def build_user_message
      parts = [@news.title]
      context = []
      context << "Person: #{@news.primary_person}" if @news.primary_person.present?
      context << "Team: #{@news.primary_team}" if @news.primary_team.present?
      context << "Action: #{@news.primary_action}" if @news.primary_action.present?
      context << "Person2: #{@news.secondary_person}" if @news.secondary_person.present?
      context << "Team2: #{@news.secondary_team}" if @news.secondary_team.present?
      parts << "Context: #{context.join(', ')}" if context.any?
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
        messages: [{ role: "user", content: build_user_message }]
      }.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Claude API error: #{response.code} — #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end
