# frozen_string_literal: true

class CreateSlaCalendars < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_calendars do |t|
      t.integer :project_id
      t.timestamps
    end
    add_index :sla_calendars, :project_id
  end
end
