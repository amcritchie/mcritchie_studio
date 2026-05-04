require "open-uri"

module Tiktok
  # Spawns the local Playwright script that uploads a Content's MP4 to
  # TikTok Studio with caption pre-filled, then leaves the browser open
  # for the human to click "Post". Returns immediately — the Node process
  # is detached so Rails doesn't block on the browser session.
  #
  # Local-only by design (requires a desktop with Chromium). Will refuse to
  # run on Heroku or in any non-development environment.
  class StudioUpload
    SCRIPT_PATH = Rails.root.join("script", "post_to_tiktok.js")

    class Error < StandardError; end
    class NotSupported < Error; end

    def initialize(content)
      @content = content
    end

    def call
      raise NotSupported, "Studio Upload is local-only — won't run in #{Rails.env}" unless Rails.env.development?
      raise Error, "wrong workflow: #{@content.workflow}" unless @content.tiktok_workflow?
      raise Error, "no final_video_url on Content" if @content.final_video_url.blank?
      raise Error, "captions empty" if @content.captions.blank?

      mp4_path  = download_mp4
      caption   = full_caption
      vibe      = Array(@content.music_suggestions).first.to_s
      log_path  = Rails.root.join("tmp", "tiktok-upload-#{@content.slug}.log")

      pid = Process.spawn(
        { "TIKTOK_PROFILE_DIR" => ENV["TIKTOK_PROFILE_DIR"].to_s },
        "node", SCRIPT_PATH.to_s, mp4_path.to_s, caption, vibe,
        chdir: Rails.root.to_s,
        out:   log_path.to_s,
        err:   log_path.to_s
      )
      Process.detach(pid)
      { pid: pid, log: log_path.to_s, mp4: mp4_path.to_s }
    end

    private

    def full_caption
      hashtag_str = Array(@content.hashtags).map { |h| "##{h}" }.join(" ")
      [@content.captions, hashtag_str.presence].compact.join("\n\n")
    end

    def download_mp4
      dest = Rails.root.join("tmp", "tiktok-uploads", "#{@content.slug}.mp4")
      FileUtils.mkdir_p(dest.dirname)
      URI.parse(@content.final_video_url).open(read_timeout: 60) do |io|
        File.open(dest, "wb") { |f| IO.copy_stream(io, f) }
      end
      dest
    end
  end
end
