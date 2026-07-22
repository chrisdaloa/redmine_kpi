# frozen_string_literal: true

module RedmineSla
  # Computes deadlines and elapsed durations against a working-hours calendar
  # (weekly working windows + holidays), ignoring wall-clock time outside
  # those windows. Does not know about issue-level pauses: callers compose
  # pause handling on top by adjusting the resulting instant.
  #
  # Assumption: no DST handling. A calendar spanning a DST transition may be
  # off by up to 60 minutes. Accepted limitation for v1.
  class BusinessCalendar
    # working_hours: Hash{wday(0-6) => Array<[start_minute, end_minute]>} (minutes
    # since midnight). Each day's segments must be sorted and non-overlapping; a
    # day with more than one segment has a break (e.g. lunch) between them.
    # Absence of a wday key means that day is not a working day.
    # holidays: Enumerable of Date.
    def initialize(working_hours:, holidays: [])
      @working_hours = working_hours
      @holidays = holidays.to_set
    end

    def add_working_minutes(start_at, minutes)
      cursor = first_working_instant(start_at)
      remaining = minutes
      loop do
        segment_end = current_segment_end(cursor)
        available = ((segment_end - cursor) / 60).to_i
        return cursor + remaining.minutes if remaining <= available

        remaining -= available
        cursor = first_working_instant(segment_end)
      end
    end

    def elapsed_working_minutes(start_at, end_at)
      total = 0
      cursor = start_at
      while cursor < end_at
        segments = @working_hours[cursor.wday]
        if segments.blank? || @holidays.include?(cursor.to_date)
          cursor = cursor.midnight + 1.day
          next
        end

        segments.each do |start_minute, end_minute|
          day_start = cursor.midnight + start_minute.minutes
          day_end = cursor.midnight + end_minute.minutes
          segment_start = [ cursor, day_start ].max
          segment_end = [ end_at, day_end ].min

          total += ((segment_end - segment_start) / 60).to_i if segment_end > segment_start
        end
        cursor = cursor.midnight + 1.day
      end
      total
    end

    private

    def first_working_instant(instant)
      loop do
        segments = @working_hours[instant.wday]
        if segments.blank? || @holidays.include?(instant.to_date)
          instant = instant.midnight + 1.day
          next
        end

        landed = landing_instant(instant, segments)
        return landed if landed

        instant = instant.midnight + 1.day
      end
    end

    # Given an instant already known to fall on a working day, finds where it
    # lands within that day's segments: snapped forward to the next segment
    # start if it's in a gap (e.g. a lunch break), left as-is if it's already
    # inside a segment, or nil if it's past the day's last segment.
    def landing_instant(instant, segments)
      segments.each do |start_minute, end_minute|
        day_start = instant.midnight + start_minute.minutes
        day_end = instant.midnight + end_minute.minutes
        return day_start if instant < day_start
        return instant if instant < day_end
      end
      nil
    end

    def current_segment_end(instant)
      segments = @working_hours.fetch(instant.wday)
      _, end_minute = segments.find do |start_minute, seg_end_minute|
        instant >= instant.midnight + start_minute.minutes && instant < instant.midnight + seg_end_minute.minutes
      end
      instant.midnight + end_minute.minutes
    end
  end
end
