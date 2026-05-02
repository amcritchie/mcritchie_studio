require "open-uri"

class Content
  # Posts a starter_post_x Content piece to X programmatically:
  # downloads the final video from S3 → uploads via X API → creates the tweet →
  # records post URL/ID and advances stage to "posted".
  class PostToX
    def initialize(content)
      @content = content
    end

    def call
      raise "wrong workflow: #{@content.workflow}" unless @content.workflow == "starter_post_x"
      raise "no final_video_url on Content" if @content.final_video_url.blank?
      raise "captions empty — nothing to post" if @content.captions.blank?

      Dir.mktmpdir("x-post-#{@content.slug}-") do |tmp|
        path = File.join(tmp, "video.mp4")
        download_video(@content.final_video_url, path)

        result = X::PostMedia.new(text: @content.captions, video_path: path).call

        Content::Post.new(@content).call(
          platform: "x",
          post_url: result[:post_url],
          post_id:  result[:post_id]
        )
      end
      @content
    end

    private

    def download_video(url, dest)
      URI.parse(url).open(read_timeout: 60) do |io|
        File.open(dest, "wb") { |f| IO.copy_stream(io, f) }
      end
    end
  end
end
