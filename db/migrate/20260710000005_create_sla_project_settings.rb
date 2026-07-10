# frozen_string_literal: true

class CreateSlaProjectSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_project_settings do |t|
      t.integer :project_id, null: false
      t.integer :risk_threshold_percent
      t.json :resolved_status_ids
      t.json :pause_status_ids
      t.timestamps
    end
    add_index :sla_project_settings, :project_id, unique: true
  end
end
