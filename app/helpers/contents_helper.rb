module ContentsHelper
  def content_stage_scheme(stage)
    case stage.to_s
    when "idea"     then "stage-fresh"
    when "hook"     then "stage-shaping"
    when "script"   then "stage-structured"
    when "assets"   then "stage-refined"
    when "assembly" then "stage-cohered"
    when "posted"   then "stage-shipped"
    when "reviewed" then "stage-closed"
    else "neutral"
    end
  end
end
