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
end
