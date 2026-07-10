# frozen_string_literal: true

module RedmineSla
  class SlaHoliday < ApplicationRecord
    self.table_name = "sla_holidays"

    belongs_to :sla_calendar, class_name: "RedmineSla::SlaCalendar", foreign_key: :calendar_id, inverse_of: :sla_holidays

    validates :date, presence: true, uniqueness: { scope: :calendar_id }
  end
end
