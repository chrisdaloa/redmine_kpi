# frozen_string_literal: true

class AddAttesaMinutesToSlaIssueMetrics < ActiveRecord::Migration[7.2]
  def change
    add_column :sla_issue_metrics, :attesa_cliente_minutes, :integer, default: 0, null: false
    add_column :sla_issue_metrics, :attesa_interna_minutes, :integer, default: 0, null: false
    add_column :sla_issue_metrics, :attesa_cliente_since, :datetime
    add_column :sla_issue_metrics, :attesa_interna_since, :datetime
  end
end
