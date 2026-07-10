# frozen_string_literal: true

class CreateSlaCalendarDays < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_calendar_days do |t|
      t.integer :calendar_id, null: false
      t.integer :wday, null: false
      t.integer :start_minute, null: false
      t.integer :end_minute, null: false
      t.timestamps
    end
    add_index :sla_calendar_days, [ :calendar_id, :wday ], unique: true, name: "index_sla_calendar_days_on_calendar_id_and_wday"
  end
end
