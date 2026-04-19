namespace :news do
  desc "Fetch latest Adam Schefter tweet (Turf Monster intake)"
  task intake: :environment do
    news = News::Intake.new.call
    if news
      puts "Created: #{news.title.truncate(80)} (#{news.slug})"
    else
      puts "No new tweets found"
    end
  end

  desc "Review a news article via AI (extracts people, teams, action from tweet)"
  task review: :environment do
    news = if ENV["SLUG"]
      News::ReviewAgent.new(News.find_by!(slug: ENV["SLUG"])).call
    else
      News::ReviewAgent.review_latest
    end

    puts "Reviewed: #{news.title.truncate(80)} (#{news.slug})"
    puts "  Person:  #{news.primary_person}"
    puts "  Team:    #{news.primary_team}"
    puts "  Action:  #{news.primary_action}"
    puts "  Person2: #{news.secondary_person}" if news.secondary_person.present?
    puts "  Team2:   #{news.secondary_team}" if news.secondary_team.present?
    puts "Done — stage is now '#{news.stage}'"
  end

  desc "Process a reviewed article (generate slugs, create Person/Team/Contract records)"
  task process: :environment do
    news = if ENV["SLUG"]
      News.find_by!(slug: ENV["SLUG"])
    else
      News.where(stage: "reviewed").order(position: :desc, created_at: :desc).first
    end
    raise "No reviewed articles to process" unless news

    processor = News::Process.new(news)
    processor.call

    puts "Processed: #{news.title.truncate(80)} (#{news.slug})"
    puts "  Person slug:  #{news.primary_person_slug}"
    puts "  Team slug:    #{news.primary_team_slug}"
    puts "  Person2 slug: #{news.secondary_person_slug}" if news.secondary_person_slug.present?
    puts "  Team2 slug:   #{news.secondary_team_slug}" if news.secondary_team_slug.present?
    processor.created_records.each do |rec|
      label = rec[:role].tr("_", " ").capitalize
      emoji = rec[:status] == "created" ? "+" : (rec[:status] == "found" ? "=" : "?")
      puts "  [#{emoji}] #{label}: #{rec[:type]} '#{rec[:slug]}' #{rec[:status]}"
    end
    puts "Done — stage is now '#{news.stage}'"
  end

  desc "Refine a processed article via AI (generate title_short, summary, feeling)"
  task refine: :environment do
    news = if ENV["SLUG"]
      News::RefineAgent.new(News.find_by!(slug: ENV["SLUG"])).call
    else
      News::RefineAgent.refine_latest
    end

    puts "Refined: #{news.title.truncate(80)} (#{news.slug})"
    puts "  Title short: #{news.title_short}"
    puts "  Feeling:     #{news.feeling_emoji} #{news.feeling}"
    puts "  Summary:     #{news.summary&.truncate(100)}"
    puts "Done — stage is now '#{news.stage}'"
  end

  desc "Conclude a refined article via AI (generate opinion, callback)"
  task conclude: :environment do
    news = if ENV["SLUG"]
      News::ConcludeAgent.new(News.find_by!(slug: ENV["SLUG"])).call
    else
      News::ConcludeAgent.conclude_latest
    end

    puts "Concluded: #{news.title.truncate(80)} (#{news.slug})"
    puts "  Opinion:  #{news.opinion&.truncate(100)}"
    puts "  Callback: #{news.callback&.truncate(100)}"
    puts "Done — stage is now '#{news.stage}'"
  end

  desc "Create content idea from next concluded article (or SLUG=news-xxx)"
  task create_content: :environment do
    news = if ENV["SLUG"]
      News.find_by!(slug: ENV["SLUG"])
    else
      News.where(stage: "concluded").order(position: :desc, created_at: :desc).first
    end
    raise "No concluded articles to create content from" unless news

    content = Content.create!(
      title: "#{news.title_short.presence || news.title} — TikTok",
      description: news.summary,
      source_type: "news",
      source_news_slug: news.slug
    )

    puts "Content created: #{content.title.truncate(80)} (#{content.slug})"
    puts "  From news: #{news.title.truncate(60)} (#{news.slug})"
    puts "  Stage: #{content.stage}"
  end
end
