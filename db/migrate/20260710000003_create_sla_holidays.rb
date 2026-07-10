# frozen_string_literal: true

class CreateSlaHolidays < ActiveRecord::Migration[7.2]
  def change
    create_table :sla_holidays do |t|
      t.integer :calendar_id, null: false
      t.date :date, null: false
      t.string :name
      t.timestamps
    end
    add_index :sla_holidays, [ :calendar_id, :date ], unique: true, name: "index_sla_holidays_on_calendar_id_and_date"
  end
end
