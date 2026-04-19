class Content
  class Hook
    def initialize(content)
      @content = content
    end

    def call(fields)
      @content.update!(
        hook_image_url: fields[:hook_image_url],
        hook_ideas: fields[:hook_ideas] || [],
        selected_hook_index: fields[:selected_hook_index]
      )
      @content.hook!
      @content
    end
  end
end
