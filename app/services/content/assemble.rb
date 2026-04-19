class Content
  class Assemble
    def initialize(content)
      @content = content
    end

    def call(fields)
      @content.update!(
        final_video_url: fields[:final_video_url],
        music_track: fields[:music_track],
        text_overlays: fields[:text_overlays] || [],
        logo_overlay: fields.fetch(:logo_overlay, true)
      )
      @content.assemble!
      @content
    end
  end
end
