# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SlaCalendarTest < ActiveSupport::TestCase
  context "validations" do
    should "allow project_id to be nil (the global calendar)" do
      calendar = build(:sla_calendar, project_id: nil)
      assert calendar.valid?
    end

    should "reject a second calendar for the same project" do
      create(:sla_calendar, project_id: 1)
      duplicate = build(:sla_calendar, project_id: 1)
      assert_not duplicate.valid?
    end

    should "reject a second global calendar" do
      create(:sla_calendar, project_id: nil)
      duplicate = build(:sla_calendar, project_id: nil)
      assert_not duplicate.valid?
    end
  end

  context "associations" do
    should "destroy dependent calendar days and holidays when destroyed" do
      calendar = create(:sla_calendar)
      day = create(:sla_calendar_day, sla_calendar: calendar)
      holiday = create(:sla_holiday, sla_calendar: calendar)

      calendar.destroy

      assert_raises(ActiveRecord::RecordNotFound) { day.reload }
      assert_raises(ActiveRecord::RecordNotFound) { holiday.reload }
    end
  end

  context ".global" do
    should "find the calendar with a nil project_id" do
      global = create(:sla_calendar, project_id: nil)
      create(:sla_calendar, project_id: 1)

      assert_equal global, RedmineSla::SlaCalendar.global
    end
  end

  context ".for_project" do
    should "return the project calendar when one exists" do
      create(:sla_calendar, project_id: nil)
      project_calendar = create(:sla_calendar, project_id: 1)

      assert_equal project_calendar, RedmineSla::SlaCalendar.for_project(1)
    end

    should "fall back to the global calendar when the project has none" do
      global = create(:sla_calendar, project_id: nil)

      assert_equal global, RedmineSla::SlaCalendar.for_project(1)
    end
  end

  context "#business_calendar" do
    should "build a BusinessCalendar reflecting the configured days and holidays" do
      calendar = create(:sla_calendar)
      create(:sla_calendar_day, sla_calendar: calendar, wday: 1, start_minute: 540, end_minute: 1020)
      create(:sla_holiday, sla_calendar: calendar, date: Date.new(2026, 7, 6))

      business_calendar = calendar.business_calendar
      # Only Mondays are configured as working days, and this particular Monday
      # is a holiday, so the next working instant is the following Monday.
      result = business_calendar.add_working_minutes(Time.zone.local(2026, 7, 6, 8, 0), 30)
      assert_equal Time.zone.local(2026, 7, 13, 9, 30), result
    end
  end
end
