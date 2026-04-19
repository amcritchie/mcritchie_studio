class Content
  class Script
    def initialize(content)
      @content = content
    end

    def call(fields)
      @content.update!(
        script_text: fields[:script_text],
        duration_seconds: fields[:duration_seconds],
        scenes: fields[:scenes] || []
      )
      @content.script!
      @content
    end
  end
end
