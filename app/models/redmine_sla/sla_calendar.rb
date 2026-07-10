# frozen_string_literal: true

module RedmineSla
  class SlaCalendar < ApplicationRecord
    self.table_name = "sla_calendars"

    has_many :sla_calendar_days, class_name: "RedmineSla::SlaCalendarDay", foreign_key: :calendar_id, dependent: :destroy, inverse_of: :sla_calendar
    has_many :sla_holidays, class_name: "RedmineSla::SlaHoliday", foreign_key: :calendar_id, dependent: :destroy, inverse_of: :sla_calendar

    validates :project_id, uniqueness: true

    def self.global
      find_by(project_id: nil)
    end

    def self.for_project(project_id)
      find_by(project_id: project_id) || global
    end

    def business_calendar
      RedmineSla::BusinessCalendar.new(
        working_hours: sla_calendar_days.each_with_object({}) { |day, hours| hours[day.wday] = [ day.start_minute, day.end_minute ] },
        holidays: sla_holidays.pluck(:date)
      )
    end
  end
end
