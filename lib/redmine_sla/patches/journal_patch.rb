# frozen_string_literal: true

module RedmineSla
  module Patches
    module JournalPatch
      def self.included(base)
        base.class_eval do
          after_create :recalculate_sla_metrics
        end
      end

      private

      def recalculate_sla_metrics
        RedmineSla::MetricsRecalculator.call(issue)
      end
    end
  end
end
