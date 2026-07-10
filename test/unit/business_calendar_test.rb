# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::BusinessCalendarTest < ActiveSupport::TestCase
  # Monday-Friday 9:00-17:00, except Wednesday which is only 9:00-13:00.
  # wday: 0=Sunday .. 6=Saturday
  def full_week_calendar(holidays: [])
    RedmineSla::BusinessCalendar.new(
      working_hours: {
        1 => [ 9 * 60, 17 * 60 ],
        2 => [ 9 * 60, 17 * 60 ],
        3 => [ 9 * 60, 13 * 60 ],
        4 => [ 9 * 60, 17 * 60 ],
        5 => [ 9 * 60, 17 * 60 ]
      },
      holidays: holidays
    )
  end

  def local(*args)
    Time.zone.local(*args)
  end

  context "add_working_minutes" do
    should "add minutes fully inside the same working day" do
      calendar = full_week_calendar
      result = calendar.add_working_minutes(local(2026, 7, 6, 10, 0), 60) # Monday
      assert_equal local(2026, 7, 6, 11, 0), result
    end

    should "snap a start before working hours to the start of the window" do
      calendar = full_week_calendar
      result = calendar.add_working_minutes(local(2026, 7, 6, 7, 0), 30)
      assert_equal local(2026, 7, 6, 9, 30), result
    end

    should "snap a start after working hours to the next working day" do
      calendar = full_week_calendar
      result = calendar.add_working_minutes(local(2026, 7, 6, 18, 0), 30)
      assert_equal local(2026, 7, 7, 9, 30), result
    end

    should "skip a weekend" do
      calendar = full_week_calendar
      result = calendar.add_working_minutes(local(2026, 7, 4, 10, 0), 30) # Saturday
      assert_equal local(2026, 7, 6, 9, 30), result # Monday
    end

    should "skip a holiday that falls on an otherwise working day" do
      calendar = full_week_calendar(holidays: [ Date.new(2026, 7, 6) ]) # Monday
      result = calendar.add_working_minutes(local(2026, 7, 6, 8, 0), 30)
      assert_equal local(2026, 7, 7, 9, 30), result # Tuesday
    end

    should "land exactly on the window boundary without rolling to the next day" do
      calendar = full_week_calendar
      result = calendar.add_working_minutes(local(2026, 7, 6, 16, 30), 30)
      assert_equal local(2026, 7, 6, 17, 0), result
    end

    should "span a weekend gap" do
      calendar = full_week_calendar
      # Friday 16:00 -> 60 min available before 17:00, 60 min remaining rolls to Monday 9:00
      result = calendar.add_working_minutes(local(2026, 7, 3, 16, 0), 120)
      assert_equal local(2026, 7, 6, 10, 0), result
    end

    should "span a holiday in the middle of a multi-day span" do
      calendar = full_week_calendar(holidays: [ Date.new(2026, 7, 8) ]) # Wednesday
      # Tuesday 16:00 -> 60 min available before 17:00, 60 min remaining skips
      # Wednesday (holiday) and lands on Thursday 9:00 + 60 = 10:00
      result = calendar.add_working_minutes(local(2026, 7, 7, 16, 0), 120)
      assert_equal local(2026, 7, 9, 10, 0), result
    end

    should "accumulate correctly across a partial working day" do
      calendar = full_week_calendar
      # Wednesday is only 9:00-13:00 (240 minutes available)
      result = calendar.add_working_minutes(local(2026, 7, 8, 9, 0), 300)
      assert_equal local(2026, 7, 9, 10, 0), result # Thursday 9:00 + 60
    end

    should "snap a zero-minute add on an off-hours start to the next working instant" do
      calendar = full_week_calendar
      result = calendar.add_working_minutes(local(2026, 7, 6, 7, 0), 0)
      assert_equal local(2026, 7, 6, 9, 0), result
    end
  end

  context "elapsed_working_minutes" do
    should "return zero when start and end are the same instant" do
      calendar = full_week_calendar
      instant = local(2026, 7, 6, 10, 0)
      assert_equal 0, calendar.elapsed_working_minutes(instant, instant)
    end

    should "sum a partial-day + full-day + partial-day span" do
      calendar = full_week_calendar
      # Monday 16:00-17:00 (60) + Tuesday 9:00-17:00 (480) + Wednesday 9:00-10:00 (60) = 600
      result = calendar.elapsed_working_minutes(
        local(2026, 7, 6, 16, 0),
        local(2026, 7, 8, 10, 0)
      )
      assert_equal 600, result
    end
  end
end
