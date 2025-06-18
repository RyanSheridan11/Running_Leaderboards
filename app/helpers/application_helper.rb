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

  def current_deadline
    @current_deadline ||= RaceDeadline.active
      .where("start_date <= ? AND due_date >= ?", Date.current, Date.current)
      .order(:due_date)
      .first
  end

  def current_deadline_link_text(deadline, short: false)
    return nil unless deadline

    if short
      "#{deadline.race_type.upcase}"
    else
      "#{deadline.race_type.upcase} Submissions"
    end
  end
end
