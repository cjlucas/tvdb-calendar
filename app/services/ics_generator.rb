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

    # Add timezone definition for New York timezone
    calendar.concat(new_york_timezone_definition)

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

    # Create timestamp for when this event was created/modified
    dtstamp = Time.current.utc.strftime("%Y%m%dT%H%M%SZ")

    event = [
      "BEGIN:VEVENT",
      "UID:#{uid}",
      "DTSTAMP:#{dtstamp}"
    ]

    # Use specific air time if available, otherwise fall back to all-day event
    if episode.has_specific_air_time?
      # Get air time in New York timezone as specified in the issue
      start_time_ny = episode.air_time_in_timezone("America/New_York")
      end_time_ny = episode.end_time_in_timezone("America/New_York")

      if start_time_ny.present?
        # Format as datetime with timezone for ICS
        dtstart = start_time_ny.strftime("%Y%m%dT%H%M%S")
        event << "DTSTART;TZID=America/New_York:#{dtstart}"

        if end_time_ny.present?
          dtend = end_time_ny.strftime("%Y%m%dT%H%M%S")
          event << "DTEND;TZID=America/New_York:#{dtend}"
        else
          # Default 30-minute duration if no runtime specified
          default_end = start_time_ny + 30.minutes
          dtend = default_end.strftime("%Y%m%dT%H%M%S")
          event << "DTEND;TZID=America/New_York:#{dtend}"
        end
      else
        # Fallback to all-day if time parsing failed
        date_start = episode.air_date.strftime("%Y%m%d")
        date_end = (episode.air_date + 1.day).strftime("%Y%m%d")
        event << "DTSTART;VALUE=DATE:#{date_start}"
        event << "DTEND;VALUE=DATE:#{date_end}"
      end
    else
      # All-day event (current behavior)
      date_start = episode.air_date.strftime("%Y%m%d")
      date_end = (episode.air_date + 1.day).strftime("%Y%m%d")
      event << "DTSTART;VALUE=DATE:#{date_start}"
      event << "DTEND;VALUE=DATE:#{date_end}"
    end

    event << "SUMMARY:#{escape_ics_text(episode.full_title)}"
    event << "LOCATION:#{escape_ics_text(episode.location_text)}"

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

  # US DST rules as defined by Energy Policy Act of 2005
  # DST begins: Second Sunday in March at 2:00 AM
  # DST ends: First Sunday in November at 2:00 AM
  # These rules have been stable since 2007 and are unlikely to change
  # If DST rules change, update these constants
  DST_START_RULE = "FREQ=YEARLY;BYMONTH=3;BYDAY=2SU".freeze
  DST_END_RULE = "FREQ=YEARLY;BYMONTH=11;BYDAY=1SU".freeze
  DST_TRANSITION_TIME = "T020000".freeze

  def new_york_timezone_definition
    # Generate timezone definition using current US DST rules
    # Reference: https://www.timeanddate.com/time/change/usa
    base_year = 2007 # Year current DST rules took effect

    [
      "BEGIN:VTIMEZONE",
      "TZID:America/New_York",
      "BEGIN:DAYLIGHT",
      "TZOFFSETFROM:-0500",
      "TZOFFSETTO:-0400",
      "TZNAME:EDT",
      "DTSTART:#{base_year}0311#{DST_TRANSITION_TIME}",
      "RRULE:#{DST_START_RULE}",
      "END:DAYLIGHT",
      "BEGIN:STANDARD",
      "TZOFFSETFROM:-0400",
      "TZOFFSETTO:-0500",
      "TZNAME:EST",
      "DTSTART:#{base_year}1104#{DST_TRANSITION_TIME}",
      "RRULE:#{DST_END_RULE}",
      "END:STANDARD",
      "END:VTIMEZONE"
    ]
  end
end
