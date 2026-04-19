class Content
  class Review
    def initialize(content)
      @content = content
    end

    def call(fields)
      @content.update!(
        views: fields[:views],
        likes: fields[:likes],
        comments_count: fields[:comments_count],
        shares: fields[:shares],
        review_notes: fields[:review_notes]
      )
      @content.review!
      @content
    end
  end
end
