# frozen_string_literal: true

module RedmineSla
  class ElapsedHoursColumn < QueryColumn
    def initialize(options = {})
      super(:sla_acknowledgement_elapsed_hours, options)
    end

    def value_object(issue)
      project = issue.project
      return nil unless project && project.module_enabled?(:sla) &&
        User.current.allowed_to?(:view_sla, project)

      minutes = issue.sla_metric&.acknowledgement_elapsed_minutes
      return nil unless minutes

      minutes / 60.0
    end
  end
end
