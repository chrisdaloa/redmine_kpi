# frozen_string_literal: true

module RedmineSla
  class OverallStatusColumn < QueryColumn
    ICONS = { breached: "close", at_risk: "warning", paused: "time" }.freeze

    def initialize(options = {})
      super(:sla_overall_status, options)
    end

    def value_object(issue)
      project = issue.project
      metric = issue.sla_metric
      return nil unless project && project.module_enabled?(:sla) &&
        User.current.allowed_to?(:view_sla, project) && metric

      statuses = RedmineSla::SlaRule::KPIS.map do |kpi|
        RedmineSla::KpiStatus.for(
          due_at: metric.public_send(:"#{kpi}_due_at"),
          risk_at: metric.public_send(:"#{kpi}_risk_at"),
          reached_at: metric.public_send(:"#{kpi}_reached_at"),
          paused: metric.paused_since.present?
        )
      end

      status = RedmineSla::KpiStatus.worst(statuses)
      return nil if status == :not_tracked

      icon = ICONS.fetch(status, "checked")
      ApplicationController.helpers.sprite_icon(icon, I18n.t(:"label_sla_status_#{status}"), icon_only: true)
    end
  end
end
