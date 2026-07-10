# frozen_string_literal: true

module RedmineSla
  class SlaCalendarDay < ApplicationRecord
    self.table_name = "sla_calendar_days"

    belongs_to :sla_calendar, class_name: "RedmineSla::SlaCalendar", foreign_key: :calendar_id, inverse_of: :sla_calendar_days

    validates :wday, inclusion: { in: 0..6 }
    validates :wday, uniqueness: { scope: :calendar_id }
    validates :start_minute, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
    validates :end_minute, numericality: { only_integer: true, greater_than: :start_minute, less_than_or_equal_to: 1440 }
  end
end
