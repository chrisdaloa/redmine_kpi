# frozen_string_literal: true

class AddAcknowledgementElapsedMinutesToSlaIssueMetrics < ActiveRecord::Migration[7.2]
  def change
    add_column :sla_issue_metrics, :acknowledgement_elapsed_minutes, :integer
  end
end
