require_relative "../../../lib/encoding_sanitizer"

class Content
  # "Creator copilot" prep step. Runs after the lineup-graphic MP4 is rendered
  # (stage=assets) and before the human posts via TikTok Studio (stage=posted).
  #
  # Generates:
  #   - 3 hooky caption variants (different angles, all attention-grabbing)
  #   - Plain-English music vibe suggestions (NOT real track names — lets the
  #     creator search trending sounds in TikTok Studio with a target vibe)
  #   - 8-12 hashtags
  #
  # Tone is side-aware: offense gets "smooth-operation / spot-the-imposter"
  # energy, defense gets "find-the-weak-link / chaos / blitz" energy.
  #
  # Side-effects: updates caption_variants, captions (to first variant),
  # hashtags, music_suggestions, then advances stage assets → assembly.
  class PrepForTiktok
    API_URL    = "https://api.anthropic.com/v1/messages"
    MODEL      = "claude-haiku-4-5-20251001"
    MAX_TOKENS = 1024

    SYSTEM_PROMPT = <<~PROMPT
      You are a TikTok content strategist for the @turfmonstershow brand — sharp, irreverent NFL commentary. You're prepping a 19-second "find the mistake in my lineup" video for posting.

      Generate THREE distinct hooky caption variants (all attention-grabbing — no "safe" tone). Vary the ANGLE between them: a question hook, a declarative hot take, and a callout/dare. Each caption should be 1-2 short sentences, max ~140 chars. Use 0-2 emojis per caption. Make the viewer NEED to comment.

      Also suggest plain-English music VIBE descriptors (not real track names — the creator will search TikTok's trending library themselves). Examples: "punchy hip-hop with a stutter drop, 90 BPM", "ominous trap with a bass hit on the reveal", "viral 'the audacity' meme sound".

      Respond with ONLY a JSON object (no markdown, no explanation):
      {
        "caption_variants": ["variant 1 (question hook)", "variant 2 (hot take)", "variant 3 (callout)"],
        "hashtags": ["NFL", "TeamHashtag", ...],
        "music_suggestions": ["vibe descriptor 1", "vibe descriptor 2", "vibe descriptor 3"]
      }

      Rules:
      - Do NOT include # in hashtag strings
      - 8-12 hashtags total, mix broad (NFL, NFLTwitter) + team-specific
      - Caption variants should each be standalone (no shared opener) and feel meaningfully different
    PROMPT

    OFFENSE_FLAVOR = <<~FLAVOR
      SIDE: OFFENSE. Vibe: "smooth operation, who's the imposter, spot-the-weak-link in the o-line / skill players". Lean into the contrast between the polished offense and the planted mistake. References to the OL trenches, the QB's reads, route concepts — embrace football vocab.
    FLAVOR

    DEFENSE_FLAVOR = <<~FLAVOR
      SIDE: DEFENSE. Vibe: "chaos, blitz, find the imposter on the front 7 / secondary, who doesn't belong on this defense". Aggressive energy. References to pass rush, coverage breakdowns, missed tackles — embrace defensive football vocab.
    FLAVOR

    def initialize(content)
      @content = content
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def call
      raise "wrong workflow: #{@content.workflow}" unless @content.tiktok_workflow?
      raise "ANTHROPIC_API_KEY not set" if @api_key.blank?

      fields = extract_fields

      variants = Array(fields[:caption_variants]).first(3)
      raise "agent returned no caption variants" if variants.empty?

      @content.update!(
        caption_variants:   variants,
        captions:           variants.first,
        hashtags:           fields[:hashtags] || [],
        music_suggestions:  fields[:music_suggestions] || [],
        stage:              "assembly"
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
        caption_variants:  parsed["caption_variants"],
        hashtags:          parsed["hashtags"],
        music_suggestions: parsed["music_suggestions"]
      }
    end

    def build_user_message
      team_name = @content.team&.name || @content.team_slug.to_s.titleize
      mascot    = team_name.split.last
      side      = @content.lineup_side # "offense" or "defense"
      flavor    = side == "defense" ? DEFENSE_FLAVOR : OFFENSE_FLAVOR

      parts = []
      parts << flavor
      parts << "Team: #{team_name}"
      parts << "Mascot: #{mascot}"
      parts << "Hashtag handle: ##{@content.team.hashtag}" if @content.team&.hashtag.present?
      parts << "Existing draft caption: #{@content.captions}" if @content.captions.present?
      parts.join("\n")
    end

    def call_api
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"]    = "application/json"
      request["x-api-key"]       = @api_key
      request["anthropic-version"] = "2023-06-01"

      request.body = {
        model:    MODEL,
        max_tokens: MAX_TOKENS,
        system:   SYSTEM_PROMPT,
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
