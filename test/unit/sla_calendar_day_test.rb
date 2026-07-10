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
  end
end
