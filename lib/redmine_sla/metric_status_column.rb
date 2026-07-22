# frozen_string_literal: true

module RedmineSla
  class MetricStatusColumn < QueryColumn
    def initialize(kpi, options = {})
      @kpi = kpi
      super(:"sla_#{kpi}_status", options)
    end

    def value_object(issue)
      project = issue.project
      return nil unless project && project.module_enabled?(:sla) &&
        User.current.allowed_to?(:view_sla, project)

      metric = issue.sla_metric
      status = RedmineSla::KpiStatus.for(
        due_at: metric&.public_send(:"#{@kpi}_due_at"),
        risk_at: metric&.public_send(:"#{@kpi}_risk_at"),
        reached_at: metric&.public_send(:"#{@kpi}_reached_at"),
        paused: metric&.paused_since.present?
      )
      I18n.t(:"label_sla_status_#{status}")
    end
  end
end
