module ApplicationHelper
  def format_distance(meters)
    return "N/A" unless meters.present?
    km = meters / 1000.0
    "%.2f km" % km
  end

  def activity_status_badge(activity)
    if activity[:created_run]
      content_tag :span, "✓ Run Created", class: "badge badge-success"
    elsif activity[:processed]
      content_tag :span, "○ Processed", class: "badge badge-warning"
    elsif activity[:is_5k]
      content_tag :span, "○ 5K Eligible", class: "badge badge-info"
    else
      content_tag :span, "○ Not 5K", class: "badge badge-secondary"
    end
  end
end
