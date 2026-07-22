# frozen_string_literal: true

module RedmineSla
  class ProjectCustomFieldColumn < QueryColumn
    def initialize(name, setting_method, options = {})
      @setting_method = setting_method
      super(name, options)
    end

    def value_object(issue)
      project = issue.project
      return nil unless project && project.module_enabled?(:sla) &&
        User.current.allowed_to?(:view_sla, project)

      field_id = RedmineSla::SettingsResolver.new(project.id).public_send(@setting_method)
      return nil unless field_id

      project.custom_field_value(field_id)
    end
  end
end
