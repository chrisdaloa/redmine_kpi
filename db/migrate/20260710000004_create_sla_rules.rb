# frozen_string_literal: true

class CreateSlaRules < ActiveRecord::Migration[7.2]
  def change
    create_table :sla_rules do |t|
      t.integer :project_id, null: false, default: 0
      t.string :kpi, null: false
      t.integer :tracker_id, null: false, default: 0
      t.integer :priority_id, null: false, default: 0
      t.integer :target_minutes, null: false
      t.timestamps
    end
    add_index :sla_rules, [ :project_id, :kpi, :tracker_id, :priority_id ], unique: true, name: "index_sla_rules_on_scope"
  end
end
