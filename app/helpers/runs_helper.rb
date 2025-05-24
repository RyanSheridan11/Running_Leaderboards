module RunsHelper
  def format_time(seconds)
    return "N/A" unless seconds.present?

    minutes = seconds / 60
    remaining_seconds = seconds % 60
    "%d:%02d" % [minutes, remaining_seconds]
  end
end
