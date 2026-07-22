# frozen_string_literal: true

class AddBreakToSlaCalendarDays < ActiveRecord::Migration[7.2]
  def change
    add_column :sla_calendar_days, :break_start_minute, :integer
    add_column :sla_calendar_days, :break_end_minute, :integer
  end
end
