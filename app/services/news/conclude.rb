class News
  class Conclude
    def initialize(news)
      @news = news
    end

    def call(fields)
      @news.update!(
        opinion: fields[:opinion],
        callback: fields[:callback]
      )
      @news.conclude!
      @news
    end
  end
end
