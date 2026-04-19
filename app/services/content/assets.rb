class Content
  class Assets
    def initialize(content)
      @content = content
    end

    def call(fields)
      @content.update!(
        scene_assets: fields[:scene_assets] || []
      )
      @content.assets!
      @content
    end
  end
end
