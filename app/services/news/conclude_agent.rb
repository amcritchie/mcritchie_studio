class News
  class ConcludeAgent
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-haiku-4-5-20251001"
    MAX_TOKENS = 512

    SYSTEM_PROMPT = <<~PROMPT
      You are a sports content strategist for a pick'em gaming platform focused on the 2026 World Cup. Given a refined news article, generate an editorial opinion and a callback action.

      Respond with ONLY a JSON object (no markdown, no explanation) with these fields:
      - opinion: A 2-4 sentence editorial take on the news from the perspective of a sports gaming platform. What does this mean for fans, bettors, and the tournament? Be opinionated but fair.
      - callback: A 1-2 sentence action item — what content, feature, or follow-up should the platform create in response to this news? Be specific and actionable.

      Examples:
      Title: "Mahomes Signs Record $450M Extension"
      Summary: "Patrick Mahomes has locked in with the Kansas City Chiefs on a historic 10-year, $450 million extension."
      Feeling: hyped
      {"opinion":"This is the kind of commitment that reshapes a franchise for a decade. Mahomes is the safest bet in football, and this extension means Chiefs props will be premium content for years. The real question is whether the cap hit affects their supporting cast.","callback":"Create a 'Mahomes Era' prop series highlighting key career milestones he could hit during the extension."}
    PROMPT

    def self.conclude_latest
      news = News.where(stage: "refined").order(position: :desc, created_at: :desc).first
      raise "No refined articles to conclude" unless news

      new(news).call
    end

    def initialize(news)
      @news = news
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def call
      raise "ANTHROPIC_API_KEY not set" if @api_key.blank?
      raise "News must be in refined stage" unless @news.stage == "refined"

      fields = extract_fields
      News::Conclude.new(@news).call(fields)
      @news
    end

    private

    def extract_fields
      response = call_api
      text = response.dig("content", 0, "text") || raise("Empty response from Claude API")
      text = text.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "").strip
      parsed = JSON.parse(text)

      {
        opinion: parsed["opinion"],
        callback: parsed["callback"]
      }
    end

    def build_user_message
      parts = []
      parts << "Title: #{@news.title_short || @news.title}"
      parts << "Summary: #{@news.summary}" if @news.summary.present?
      parts << "Feeling: #{@news.feeling}" if @news.feeling.present?
      parts << "What happened: #{@news.what_happened}" if @news.what_happened.present?
      parts << "Person: #{@news.primary_person}" if @news.primary_person.present?
      parts << "Team: #{@news.primary_team}" if @news.primary_team.present?
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
