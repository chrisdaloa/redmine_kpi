# frozen_string_literal: true

module RedmineSla
  class IssueMetric < ApplicationRecord
    self.table_name = "sla_issue_metrics"

    belongs_to :issue, inverse_of: :sla_metric

    validates :issue_id, presence: true, uniqueness: true
  end
end
