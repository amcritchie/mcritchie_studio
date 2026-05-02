module X
  # Posts a video tweet via the X API: v1.1 chunked media upload + v2 /tweets.
  #
  # Required env vars:
  #   X_API_KEY, X_API_SECRET, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET
  #
  # The X app's permissions must be set to "Read and Write" — read-only access
  # tokens 401 on APPEND.
  #
  # Video must be ≤60fps (X's spec). Captures from this app run ffmpeg with
  # `fps=30` for safety; videos at 77fps get rejected as "media IDs invalid".
  class PostMedia
    UPLOAD_URL = "https://upload.twitter.com/1.1/media/upload.json".freeze
    TWEETS_URL = "https://api.twitter.com/2/tweets".freeze
    CHUNK_SIZE = 4 * 1024 * 1024 # 4MB; X caps APPEND chunks at 5MB

    class Error < StandardError; end
    class NotConfigured < Error; end

    def initialize(text:, video_path:, media_category: "tweet_video", client: Client.new)
      @text           = text.to_s
      @video_path     = video_path.to_s
      @media_category = media_category
      @client         = client
      raise Error, "video file not found: #{@video_path}" unless File.exist?(@video_path)
      raise NotConfigured, "X creds missing" unless OAuthSigner.creds_present?
    end

    # Returns { post_id:, post_url: }.
    def call
      media_id = upload_video
      tweet    = create_tweet(media_id)
      tweet_id = tweet.dig("data", "id") or raise Error, "tweet response missing data.id: #{tweet.inspect}"
      { post_id: tweet_id, post_url: "https://x.com/i/web/status/#{tweet_id}" }
    end

    private

    def upload_video
      total_bytes = File.size(@video_path)
      media_id = init_upload(total_bytes)
      append_chunks(media_id)
      finalize_upload(media_id)
      wait_for_processing(media_id)
      # Propagation buffer: STATUS reports the upload backend is ready, but the
      # v2 /tweets cache lags a few seconds. Without this pause /tweets often
      # rejects the media_id with "Your media IDs are invalid" on first try.
      sleep 3
      media_id
    end

    def init_upload(total_bytes)
      json = @client.parse_json(@client.post_form(UPLOAD_URL,
        "command"        => "INIT",
        "total_bytes"    => total_bytes.to_s,
        "media_type"     => "video/mp4",
        "media_category" => @media_category
      ))
      json["media_id_string"] or raise Error, "INIT missing media_id_string: #{json.inspect}"
    end

    def append_chunks(media_id)
      seg = 0
      File.open(@video_path, "rb") do |f|
        while (chunk = f.read(CHUNK_SIZE))
          fields = {
            "command"       => "APPEND",
            "media_id"      => media_id,
            "segment_index" => seg.to_s
          }
          resp = @client.post_multipart(UPLOAD_URL, fields, media_chunk: chunk)
          unless resp.is_a?(Net::HTTPSuccess)
            raise Error, "APPEND seg=#{seg} failed: #{resp.code} #{resp.body}"
          end
          seg += 1
        end
      end
    end

    def finalize_upload(media_id)
      @client.parse_json(@client.post_form(UPLOAD_URL,
        "command" => "FINALIZE", "media_id" => media_id))
    end

    def wait_for_processing(media_id, max_wait: 240)
      deadline = Time.now + max_wait
      loop do
        resp = @client.get(UPLOAD_URL, "command" => "STATUS", "media_id" => media_id)
        json = @client.parse_json(resp)
        info = json.dig("data", "processing_info") || json["processing_info"]
        return unless info
        case info["state"]
        when "succeeded" then return
        when "failed"    then raise Error, "media processing failed: #{info.inspect}"
        when "in_progress", "pending"
          raise Error, "media processing timed out after #{max_wait}s" if Time.now > deadline
          sleep(info["check_after_secs"] || 3)
        else
          raise Error, "unknown processing state: #{info.inspect}"
        end
      end
    end

    def create_tweet(media_id, attempt: 1)
      resp = @client.post_json(TWEETS_URL, text: @text, media: { media_ids: [media_id] })
      return @client.parse_json(resp) if resp.is_a?(Net::HTTPSuccess)

      # Retry once on the propagation-lag signature.
      if attempt == 1 && resp.code == "400" && resp.body.to_s.include?("media IDs are invalid")
        sleep 5
        return create_tweet(media_id, attempt: 2)
      end
      raise Error, "tweet create failed: #{resp.code} #{resp.body}"
    end
  end
end
