class News
  class Refine
    def initialize(news)
      @news = news
    end

    def call(fields)
      @news.update!(
        title_short: fields[:title_short],
        summary: fields[:summary],
        feeling: fields[:feeling],
        feeling_emoji: fields[:feeling_emoji],
        what_happened: fields[:what_happened]
      )
      @news.refine!
      @news
    end
  end
end
