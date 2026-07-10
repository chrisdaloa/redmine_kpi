class CreateSlaIssueMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_issue_metrics do |t|
      t.integer :issue_id, null: false

      %w[acknowledgement first_response resolution].each do |kpi|
        t.datetime :"#{kpi}_due_at"
        t.datetime :"#{kpi}_risk_at"
        t.integer :"#{kpi}_target_minutes"
        t.datetime :"#{kpi}_reached_at"
      end

      t.integer :initial_status_id
      t.datetime :paused_since
      t.integer :total_paused_minutes, null: false, default: 0

      t.timestamps
    end
    add_index :sla_issue_metrics, :issue_id, unique: true
  end
end
