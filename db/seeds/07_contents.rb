contents_data = [
  {
    title: "Messi's Last World Cup — TikTok",
    stage: "posted",
    description: "Lionel Messi has confirmed 2026 will be his last World Cup. Emotional farewell content.",
    source_type: "news",
    content_type: "tiktok_video",
    hook_ideas: ["What if I told you Messi just dropped a bombshell?", "This is the end of an era.", "Messi fans, you need to sit down for this."],
    selected_hook_index: 1,
    script_text: "The GOAT has spoken. Lionel Messi just confirmed that the 2026 World Cup will be his LAST. After winning it all in Qatar, he's going out on his own terms.",
    duration_seconds: 30,
    scenes: [
      { "scene_number" => 1, "description" => "Messi lifting 2022 trophy", "duration_seconds" => 5 },
      { "scene_number" => 2, "description" => "Interview clip with subtitle", "duration_seconds" => 10 },
      { "scene_number" => 3, "description" => "Career highlights montage", "duration_seconds" => 10 },
      { "scene_number" => 4, "description" => "End card with CTA", "duration_seconds" => 5 }
    ],
    platform: "tiktok",
    post_url: "https://tiktok.com/@mcritchie/video/example1",
    post_id: "tiktok_001"
  },
  {
    title: "Pulisic Hat Trick Breakdown",
    stage: "script",
    description: "Christian Pulisic's three goals against Canada — tactical breakdown for TikTok.",
    source_type: "news",
    content_type: "tiktok_video",
    hook_ideas: ["Captain America just went CRAZY", "3 goals. 1 game. 0 mercy.", "Pulisic just silenced every doubter."],
    selected_hook_index: 0,
    script_text: "Captain America just went CRAZY. Three goals against Canada, and each one was more ruthless than the last. Let's break it down.",
    duration_seconds: 45,
    scenes: [
      { "scene_number" => 1, "description" => "Hook with Pulisic celebration", "duration_seconds" => 5 },
      { "scene_number" => 2, "description" => "Goal 1 — positioning analysis", "duration_seconds" => 12 },
      { "scene_number" => 3, "description" => "Goal 2 — first touch breakdown", "duration_seconds" => 12 },
      { "scene_number" => 4, "description" => "Goal 3 — finesse shot", "duration_seconds" => 12 },
      { "scene_number" => 5, "description" => "CTA — follow for more WC content", "duration_seconds" => 4 }
    ]
  },
  {
    title: "World Cup Group of Death Preview",
    stage: "hook",
    description: "Group F is loaded — Germany, Argentina, Nigeria, Mexico. Preview content.",
    source_type: "manual",
    content_type: "tiktok_video",
    hook_ideas: ["This World Cup group is INSANE", "4 teams. Only 2 survive.", "The group of death has been revealed."],
    selected_hook_index: 2
  },
  {
    title: "Top 5 World Cup Sleeper Teams",
    stage: "idea",
    description: "Underdog teams that could make a deep run in 2026. Great hook potential.",
    source_type: "manual",
    content_type: "tiktok_video"
  }
]

messi_news = News.find_by(title: "Messi Confirms 2026 World Cup Will Be His Last")

contents_data.each do |data|
  content = Content.find_or_create_by!(title: data[:title]) do |c|
    c.stage = data[:stage]
    c.description = data[:description]
    c.source_type = data[:source_type]
    c.content_type = data[:content_type]
    c.hook_ideas = data[:hook_ideas] || []
    c.selected_hook_index = data[:selected_hook_index]
    c.script_text = data[:script_text]
    c.duration_seconds = data[:duration_seconds]
    c.scenes = data[:scenes] || []
    c.platform = data[:platform]
    c.post_url = data[:post_url]
    c.post_id = data[:post_id]

    if data[:source_type] == "news" && messi_news && data[:title].include?("Messi")
      c.source_news_slug = messi_news.slug
    end

    case data[:stage]
    when "hook"   then c.hooked_at = 6.hours.ago
    when "script" then c.hooked_at = 1.day.ago;   c.scripted_at = 6.hours.ago
    when "posted" then c.hooked_at = 3.days.ago;   c.scripted_at = 2.days.ago; c.asset_at = 1.day.ago; c.assembled_at = 12.hours.ago; c.posted_at = 6.hours.ago
    end
  end
  puts "Content: #{content.title} (#{content.stage})"
end
