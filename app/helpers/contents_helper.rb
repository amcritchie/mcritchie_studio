module ContentsHelper
  def content_stage_scheme(stage)
    case stage.to_s
    when "idea"     then "info"
    when "hook"     then "warning"
    when "script"   then "success"
    when "assets"   then "emerald"
    when "assembly" then "violet"
    when "posted"   then "mint"
    when "reviewed" then "gray"
    else "neutral"
    end
  end
end
