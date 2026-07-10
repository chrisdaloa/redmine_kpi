# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SlaHolidayTest < ActiveSupport::TestCase
  context "validations" do
    should "be valid with a calendar and a date" do
      holiday = build(:sla_holiday)
      assert holiday.valid?
    end

    should "require a date" do
      holiday = build(:sla_holiday, date: nil)
      assert_not holiday.valid?
    end

    should "reject a duplicate date on the same calendar" do
      calendar = create(:sla_calendar)
      create(:sla_holiday, sla_calendar: calendar, date: Date.new(2026, 1, 1))
      duplicate = build(:sla_holiday, sla_calendar: calendar, date: Date.new(2026, 1, 1))
      assert_not duplicate.valid?
    end

    should "allow the same date on a different calendar" do
      create(:sla_holiday, date: Date.new(2026, 1, 1))
      other_calendar = create(:sla_calendar, project_id: 1)
      other_holiday = build(:sla_holiday, sla_calendar: other_calendar, date: Date.new(2026, 1, 1))
      assert other_holiday.valid?
    end
  end
end
