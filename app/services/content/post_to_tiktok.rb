class Content
  # Posts a starter_post_tiktok_* Content piece to TikTok via the Content
  # Posting API. Uses PULL_FROM_URL with the public S3 MP4 — no chunked
  # upload, TikTok fetches it server-side.
  #
  # publish_type defaults to :inbox so we can attach a trending sound from
  # the TikTok app before publishing. Switch to :direct_post for hands-off
  # batch posting (optionally with music_id from the Commercial Music
  # Library, requires a Business account).
  class PostToTiktok
    DEFAULT_PUBLISH_TYPE = :inbox

    def initialize(content, publish_type: nil, music_id: nil)
      @content      = content
      @publish_type = (publish_type.presence || DEFAULT_PUBLISH_TYPE).to_sym
      @music_id     = music_id
    end

    def call
      raise "wrong workflow: #{@content.workflow}" unless @content.tiktok_workflow?
      raise "no final_video_url on Content" if @content.final_video_url.blank?
      raise "captions empty — nothing to post" if @content.captions.blank?

      result = Tiktok::PostMedia.new(
        text:         @content.captions,
        video_url:    @content.final_video_url,
        publish_type: @publish_type,
        music_id:     @music_id
      ).call

      # Direct posts return a publish_id but the public URL isn't known until
      # TikTok finishes processing. Save the publish_id as post_id and a
      # placeholder URL so the timeline shows the post happened. The user
      # can paste the real URL later via post_step if they want it captured.
      placeholder_url = case @publish_type
                        when :inbox       then "tiktok://drafts/#{result[:publish_id]}"
                        else                   "tiktok://publish/#{result[:publish_id]}"
                        end

      Content::Post.new(@content).call(
        platform: "tiktok",
        post_url: placeholder_url,
        post_id:  result[:publish_id]
      )
      @content
    end
  end
end
