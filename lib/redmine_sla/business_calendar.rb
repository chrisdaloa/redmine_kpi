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
    # working_hours: Hash{wday(0-6) => [start_minute, end_minute]} (minutes since midnight).
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
        available = ((window_end(cursor) - cursor) / 60).to_i
        return cursor + remaining.minutes if remaining <= available

        remaining -= available
        cursor = first_working_instant(cursor.midnight + 1.day)
      end
    end

    def elapsed_working_minutes(start_at, end_at)
      total = 0
      cursor = start_at
      while cursor < end_at
        window = @working_hours[cursor.wday]
        if window.nil? || @holidays.include?(cursor.to_date)
          cursor = cursor.midnight + 1.day
          next
        end

        day_start = cursor.midnight + window[0].minutes
        day_end = cursor.midnight + window[1].minutes
        segment_start = [ cursor, day_start ].max
        segment_end = [ end_at, day_end ].min

        total += ((segment_end - segment_start) / 60).to_i if segment_end > segment_start
        cursor = cursor.midnight + 1.day
      end
      total
    end

    private

    def first_working_instant(instant)
      loop do
        window = @working_hours[instant.wday]
        if window.nil? || @holidays.include?(instant.to_date)
          instant = instant.midnight + 1.day
          next
        end

        day_start = instant.midnight + window[0].minutes
        day_end = instant.midnight + window[1].minutes
        return day_start if instant < day_start
        if instant >= day_end
          instant = instant.midnight + 1.day
          next
        end

        return instant
      end
    end

    def window_end(instant)
      window = @working_hours.fetch(instant.wday)
      instant.midnight + window[1].minutes
    end
  end
end
