class News
  class Conclude
    def initialize(news)
      @news = news
    end

    def call(fields)
      @news.update!(
        opinion: fields[:opinion],
        callback_ideas: fields[:callback_ideas] || []
      )
      @news.conclude!
      @news
    end
  end
end
