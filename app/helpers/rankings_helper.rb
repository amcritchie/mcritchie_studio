module RankingsHelper
  def grade_color(grade)
    if grade >= 90
      "#16a34a"
    elsif grade >= 80
      "#22c55e"
    elsif grade >= 70
      "#84cc16"
    elsif grade >= 60
      "#eab308"
    else
      "#ef4444"
    end
  end

  TIER_EMOJIS = {
    "Air Raid" => "✈️",
    "Pass Enthusiast" => "🎯",
    "Balanced-Pass" => "⚖️",
    "True Balance" => "🤝",
    "Balanced-Run" => "💪",
    "Ground & Pound" => "🚂"
  }.freeze

  TIER_BADGE_CLASSES = {
    "Air Raid" => "bg-blue-500/20 text-blue-400",
    "Pass Enthusiast" => "bg-violet-500/20 text-violet-400",
    "Balanced-Pass" => "bg-yellow-500/20 text-yellow-400",
    "True Balance" => "bg-green-500/20 text-green-400",
    "Balanced-Run" => "bg-orange-500/20 text-orange-400",
    "Ground & Pound" => "bg-red-500/20 text-red-400"
  }.freeze

  def rank_color(rank)
    if rank <= 5
      "#16a34a"
    elsif rank <= 10
      "#22c55e"
    elsif rank <= 16
      "#84cc16"
    elsif rank <= 22
      "#eab308"
    elsif rank <= 27
      "#f97316"
    else
      "#ef4444"
    end
  end

  def rank_label(rank)
    case rank
    when 1..5 then "Elite"
    when 6..10 then "Great"
    when 11..16 then "Above Avg"
    when 17..22 then "Average"
    when 23..27 then "Below Avg"
    else "Poor"
    end
  end

  def tier_emoji(tier)
    TIER_EMOJIS[tier] || "🏈"
  end

  def tier_badge_class(tier)
    TIER_BADGE_CLASSES[tier] || "bg-gray-500/20 text-gray-400"
  end
end
