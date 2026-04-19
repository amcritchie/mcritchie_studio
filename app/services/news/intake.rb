class News
  class Intake
    SCHEFTER_USERNAME = "AdamSchefter"
    BASE_URL = "https://api.x.com"

    def call
      token = ENV["X_BEARER_TOKEN"]
      raise "X_BEARER_TOKEN not set" if token.blank?

      user_id = resolve_user_id(token)
      tweets = fetch_recent_tweets(user_id, token)

      tweets.each do |tweet|
        next if News.exists?(x_post_id: tweet["id"])

        text = tweet["text"] || ""
        url = text[/https?:\/\/\S+/]

        return News.create!(
          title: text.first(255),
          x_post_id: tweet["id"],
          x_post_url: "https://x.com/#{SCHEFTER_USERNAME}/status/#{tweet['id']}",
          url: url,
          author: SCHEFTER_USERNAME,
          published_at: tweet["created_at"],
          stage: "new"
        )
      end

      nil
    end

    private

    def resolve_user_id(token)
      @user_id ||= begin
        uri = URI("#{BASE_URL}/2/users/by/username/#{SCHEFTER_USERNAME}")
        response = get(uri, token)
        data = JSON.parse(response.body)
        data.dig("data", "id") || raise("Could not resolve user ID for #{SCHEFTER_USERNAME}")
      end
    end

    def fetch_recent_tweets(user_id, token)
      uri = URI("#{BASE_URL}/2/users/#{user_id}/tweets?max_results=5&tweet.fields=created_at")
      response = get(uri, token)
      data = JSON.parse(response.body)
      data["data"] || []
    end

    def get(uri, token)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      http.request(request)
    end
  end
end
