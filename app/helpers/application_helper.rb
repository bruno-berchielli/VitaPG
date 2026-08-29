module ApplicationHelper
  # Public signup is only open to bootstrap the instance (or when explicitly
  # enabled); afterwards people join via Members invitations.
  def signups_open?
    ENV["VITAPG_OPEN_SIGNUPS"] == "1" || !User.exists?
  end

  def current_mode
    current_user&.preferences&.dig("mode") == "dark" ? "dark" : "light"
  end
  def human_size(bytes)
    return "—" if bytes.blank?

    number_to_human_size(bytes, precision: 3)
  end

  def human_duration(seconds)
    return "—" if seconds.blank?

    seconds = seconds.round
    return "#{seconds}s" if seconds < 60
    return "#{seconds / 60}m #{seconds % 60}s" if seconds < 3600

    "#{seconds / 3600}h #{(seconds % 3600) / 60}m"
  end

  # Relative time with the absolute timestamp on hover.
  def relative_time(time)
    return "—" if time.blank?

    tag.time(
      t("time_ago", time: time_ago_in_words(time)),
      datetime: time.iso8601,
      title: l(time, format: :long)
    )
  end

  def relative_time_future(time)
    return "—" if time.blank?

    tag.time(
      t("time_in", time: time_ago_in_words(time)),
      datetime: time.iso8601,
      title: l(time, format: :long)
    )
  end
end
