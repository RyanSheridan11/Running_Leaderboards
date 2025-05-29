module RunsHelper
  def format_time(seconds, race_type = "5k")
    return "N/A" unless seconds.present?

    minutes = seconds / 60
    remaining_seconds = seconds % 60

    if race_type == "bronco"
      "%d:%02d" % [minutes, remaining_seconds]  # m:ss for bronco
    else
      "%d:%02d" % [minutes, remaining_seconds]  # mm:ss for 5k
    end
  end

  def format_pace(seconds, race_type = "5k")
    return "N/A" unless seconds.present?
    distance = race_type == "bronco" ? 1.2 : 5.0
    pace_seconds = (seconds / distance).round
    minutes = pace_seconds / 60
    secs = pace_seconds % 60
    "%d:%02d /km" % [minutes, secs]
  end
end
