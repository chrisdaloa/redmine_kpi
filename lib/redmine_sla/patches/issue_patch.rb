# frozen_string_literal: true

module RedmineSla
  module Patches
    module IssuePatch
      def self.included(base)
        base.class_eval do
          has_one :sla_metric, class_name: "RedmineSla::IssueMetric", foreign_key: :issue_id, inverse_of: :issue

          after_create :recalculate_sla_metrics
          after_update :recalculate_sla_metrics, if: :sla_relevant_attribute_change?
        end
      end

      private

      def sla_relevant_attribute_change?
        saved_change_to_status_id? || saved_change_to_tracker_id? ||
          saved_change_to_priority_id? || saved_change_to_project_id?
      end

      def recalculate_sla_metrics
        RedmineSla::MetricsRecalculator.call(self)
      end
    end
  end
end
