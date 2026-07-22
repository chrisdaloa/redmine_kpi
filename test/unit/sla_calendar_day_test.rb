# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SlaCalendarDayTest < ActiveSupport::TestCase
  context "validations" do
    should "be valid with a well-formed working window" do
      day = build(:sla_calendar_day)
      assert day.valid?
    end

    should "require wday to be between 0 and 6" do
      day = build(:sla_calendar_day, wday: 7)
      assert_not day.valid?
    end

    should "reject a second row for the same wday on the same calendar" do
      calendar = create(:sla_calendar)
      create(:sla_calendar_day, sla_calendar: calendar, wday: 1)
      duplicate = build(:sla_calendar_day, sla_calendar: calendar, wday: 1)
      assert_not duplicate.valid?
    end

    should "allow the same wday on a different calendar" do
      create(:sla_calendar_day, wday: 1)
      other_calendar = create(:sla_calendar, project_id: 1)
      other_day = build(:sla_calendar_day, sla_calendar: other_calendar, wday: 1)
      assert other_day.valid?
    end

    should "require end_minute to be greater than start_minute" do
      day = build(:sla_calendar_day, start_minute: 600, end_minute: 600)
      assert_not day.valid?
    end

    should "be valid with a break fully inside the working window" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: 780, break_end_minute: 840)
      assert day.valid?
    end

    should "be valid with no break configured" do
      day = build(:sla_calendar_day, break_start_minute: nil, break_end_minute: nil)
      assert day.valid?
    end

    should "reject a break start without a break end" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: 780, break_end_minute: nil)
      assert_not day.valid?
    end

    should "reject a break end without a break start" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: nil, break_end_minute: 840)
      assert_not day.valid?
    end

    should "reject a break end that is not after the break start" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: 840, break_end_minute: 840)
      assert_not day.valid?
    end

    should "reject a break that starts before the working window" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: 480, break_end_minute: 840)
      assert_not day.valid?
    end

    should "reject a break that ends after the working window" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: 780, break_end_minute: 1140)
      assert_not day.valid?
    end

    should "not raise when the break columns are not yet present on the schema" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: nil, break_end_minute: nil)
      day.stubs(:has_attribute?).with(:break_start_minute).returns(false)
      day.stubs(:has_attribute?).with(:break_end_minute).returns(false)
      day.stubs(:break_start_minute).raises(NoMethodError)
      day.stubs(:break_end_minute).raises(NoMethodError)
      assert_nothing_raised { day.valid? }
    end
  end

  context "#segments" do
    should "return a single full-day segment when no break is configured" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: nil, break_end_minute: nil)
      assert_equal [ [ 540, 1080 ] ], day.segments
    end

    should "return two segments split around the break when configured" do
      day = build(:sla_calendar_day, start_minute: 540, end_minute: 1080, break_start_minute: 780, break_end_minute: 840)
      assert_equal [ [ 540, 780 ], [ 840, 1080 ] ], day.segments
    end
  end
end
