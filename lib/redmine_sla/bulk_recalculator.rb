# frozen_string_literal: true

module RedmineSla
  # Recalculates the sla_issue_metrics row for every issue. Used both by the
  # admin bulk-recalculation action and the redmine_sla:recalculate rake task,
  # so activating the plugin on existing data or changing rules after the fact
  # can be reconciled with a single, identical code path.
  class BulkRecalculator
    def self.call
      Issue.find_each do |issue|
        MetricsRecalculator.call(issue)
      end
    end
  end
end
