module ApplicationHelper
  def stage_scheme(stage)
    case stage.to_s
    when "new"         then "info"
    when "queued"      then "warning"
    when "in_progress" then "success"
    when "done"        then "success"
    when "failed"      then "danger"
    else "neutral"
    end
  end

  def news_stage_scheme(stage)
    case stage.to_s
    when "new"        then "info"
    when "reviewed"   then "warning"
    when "processed"  then "success"
    when "refined"    then "emerald"
    when "concluded"  then "violet"
    when "archived"   then "gray"
    else "neutral"
    end
  end
end
