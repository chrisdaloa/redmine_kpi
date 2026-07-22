# frozen_string_literal: true

module RedmineSla
  class AttesaHoursColumn < QueryColumn
    def initialize(kind, options = {})
      @kind = kind
      super(:"sla_#{kind}_hours", options)
    end

    def value_object(issue)
      project = issue.project
      return nil unless project && project.module_enabled?(:sla) &&
        User.current.allowed_to?(:view_sla, project)

      metric = issue.sla_metric
      return nil unless metric

      stored_minutes = metric.public_send(:"#{@kind}_minutes")
      since = metric.public_send(:"#{@kind}_since")
      live_minutes = since ? live_elapsed_minutes(project, since) : 0

      (stored_minutes + live_minutes) / 60.0
    end

    private

    def live_elapsed_minutes(project, since)
      calendar = RedmineSla::SlaCalendar.for_project(project.id)&.business_calendar
      return 0 unless calendar

      calendar.elapsed_working_minutes(since, Time.current)
    end
  end
end
