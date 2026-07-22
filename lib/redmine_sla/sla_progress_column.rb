# frozen_string_literal: true

module RedmineSla
  class SlaProgressColumn < QueryColumn
    def initialize(kpi, options = {})
      @kpi = kpi
      super(:"sla_#{kpi}_progress", options)
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
      label = I18n.t(:"label_sla_status_#{status}")
      return label if status == :not_tracked

      percent = percent_complete(issue, metric)
      return label unless percent

      progress_bar(status, percent, label)
    end

    private

    # Visually caps the bar at 100% (a breached kpi can be several times over
    # target), but keeps the real percentage in the label text -- the colored
    # bar is a glance-able indicator, the number stays the source of truth.
    # The status word itself is already conveyed by the bar color, so it only
    # goes into the title tooltip instead of repeating it in visible text.
    def progress_bar(status, percent, label)
      helpers = ApplicationController.helpers
      fill = helpers.content_tag(:span, "", class: "sla-progress-fill", style: "width: #{[ percent, 100 ].min}%;")
      track = helpers.content_tag(:span, fill, class: "sla-progress-track")
      text = helpers.content_tag(:span, "#{percent}%", class: "sla-progress-label")
      helpers.content_tag(:span, track + text, class: "sla-progress sla-progress-#{status}", title: label)
    end

    def percent_complete(issue, metric)
      target = metric.public_send(:"#{@kpi}_target_minutes")
      calendar = RedmineSla::SlaCalendar.for_project(issue.project_id)&.business_calendar
      return nil unless target&.positive? && calendar

      reached_at = metric.public_send(:"#{@kpi}_reached_at")
      elapsed = calendar.elapsed_working_minutes(issue.created_on, reached_at || Time.current)
      ((elapsed.to_f / target) * 100).round
    end
  end
end
