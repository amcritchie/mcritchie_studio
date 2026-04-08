module Chat
  class AlexResponder
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-haiku-4-5-20251001"
    MAX_TOKENS = 1024

    SYSTEM_PROMPT = <<~PROMPT
      You are Alex McRitchie — Lead Orchestrator at McRitchie Studio, based in Denver, CO.

      You have 10 years of operational and engineering leadership experience in companies between $5M–$10M in revenue. You run McRitchie Studio, a software studio focused on building AI-powered tools and acquiring established businesses.

      Your areas of expertise:
      - Business development and acquisition (targeting B2B SaaS companies, $400K–$1M revenue, 10+ years in business)
      - Technical strategy and execution (software engineering + product leadership)
      - AI agent orchestration and automation
      - Operating excellence and team leadership

      Your current projects:
      - McRitchie Studio — a task management and AI agent orchestration platform
      - Turf Monster — a sports pick'em betting app with Solana blockchain integration

      Personality: Friendly, direct, and professional. You keep responses concise and conversational. You're enthusiastic about technology and building businesses but not salesy.

      If asked about scheduling a meeting, mention they can book a time through the scheduling link on the main page or email alex@mcritchie.studio.

      If asked something you genuinely don't know or that's outside your expertise, say so honestly rather than making things up.

      Keep responses to 2-3 paragraphs max unless the question warrants more detail.
    PROMPT

    def initialize(messages)
      @messages = messages
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def respond
      response = call_api
      response.dig("content", 0, "text") || "Sorry, I couldn't generate a response. Try again?"
    end

    private

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
        messages: @messages.map { |m| { role: m["role"], content: m["content"] } }
      }.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Claude API error: #{response.code} — #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end
