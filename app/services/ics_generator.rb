class IcsGenerator
  def initialize(user)
    @user = user
  end

  def generate
    calendar = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//TVDB Calendar//NONSGML v1.0//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "X-WR-CALNAME:TV Shows",
      "X-WR-CALDESC:Upcoming episodes for your favorite TV shows from TheTVDB"
    ]

    episodes = @user.episodes.upcoming.includes(:series).order(:air_date)

    episodes.each do |episode|
      calendar.concat(build_event(episode))
    end

    calendar << "END:VCALENDAR"
    calendar.join("\r\n")
  end

  private

  def build_event(episode)
    # Generate unique ID for the event
    uid = "episode-#{episode.id}-#{episode.series.tvdb_id}@tvdbcalendar.com"

    # Format dates for ICS (YYYYMMDD)
    date_start = episode.air_date.strftime("%Y%m%d")
    date_end = episode.air_date.strftime("%Y%m%d")

    # Create timestamp for when this event was created/modified
    dtstamp = Time.current.utc.strftime("%Y%m%dT%H%M%SZ")

    event = [
      "BEGIN:VEVENT",
      "UID:#{uid}",
      "DTSTAMP:#{dtstamp}",
      "DTSTART;VALUE=DATE:#{date_start}",
      "DTEND;VALUE=DATE:#{date_end}",
      "SUMMARY:#{escape_ics_text(episode.full_title)}",
      "LOCATION:#{escape_ics_text(episode.location_text)}"
    ]

    # Add description with IMDB link if available
    if episode.series.imdb_url
      description = "Watch on IMDB: #{episode.series.imdb_url}"
      event << "DESCRIPTION:#{escape_ics_text(description)}"
      event << "URL:#{episode.series.imdb_url}"
    end

    event << "END:VEVENT"
    event
  end

  def escape_ics_text(text)
    return "" if text.blank?

    # Escape special characters for ICS format
    text.gsub(/[\\,;"]/) { |match| "\\#{match}" }
        .gsub(/\n/, "\\n")
        .gsub(/\r/, "")
  end
end
