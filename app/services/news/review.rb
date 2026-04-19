class News
  class Review
    def initialize(news)
      @news = news
    end

    def call(fields)
      @news.update!(
        primary_person: fields[:primary_person],
        primary_team: fields[:primary_team],
        primary_action: fields[:primary_action],
        secondary_person: fields[:secondary_person],
        secondary_team: fields[:secondary_team],
        article_image_url: fields[:article_image_url]
      )
      @news.review!
      @news
    end
  end
end
