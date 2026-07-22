# frozen_string_literal: true

module RedmineSla
  class SlaCalendarDay < ApplicationRecord
    self.table_name = "sla_calendar_days"

    belongs_to :sla_calendar, class_name: "RedmineSla::SlaCalendar", foreign_key: :calendar_id, inverse_of: :sla_calendar_days

    validates :wday, inclusion: { in: 0..6 }
    validates :wday, uniqueness: { scope: :calendar_id }
    validates :start_minute, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
    validates :end_minute, numericality: { only_integer: true, greater_than: :start_minute, less_than_or_equal_to: 1440 }
    validates :break_start_minute,
      numericality: { only_integer: true, greater_than_or_equal_to: :start_minute, less_than: :end_minute },
      allow_nil: true, if: -> { has_attribute?(:break_end_minute) && break_end_minute.present? }
    validates :break_end_minute,
      numericality: { only_integer: true, greater_than: :break_start_minute, less_than_or_equal_to: :end_minute },
      allow_nil: true, if: -> { has_attribute?(:break_start_minute) && break_start_minute.present? }
    validate :break_bounds_are_paired

    # A day's working segments: a single full-day window, or two windows split
    # around the lunch break when one is configured.
    def segments
      return [ [ start_minute, end_minute ] ] unless break_start_minute && break_end_minute

      [ [ start_minute, break_start_minute ], [ break_end_minute, end_minute ] ]
    end

    private

    def break_bounds_are_paired
      return unless has_attribute?(:break_start_minute) && has_attribute?(:break_end_minute)
      return if break_start_minute.present? == break_end_minute.present?

      errors.add(:break_start_minute, "must be set together with break end")
    end
  end
end
