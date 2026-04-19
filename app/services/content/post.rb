class Content
  class Post
    def initialize(content)
      @content = content
    end

    def call(fields)
      @content.update!(
        platform: fields[:platform] || "tiktok",
        post_url: fields[:post_url],
        post_id: fields[:post_id],
        posted_at: fields[:posted_at] || Time.current
      )
      @content.post!
      @content
    end
  end
end
