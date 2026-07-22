# frozen_string_literal: true

module RedmineSla
  module Patches
    module ApplicationHelperPatch
      def sla_settings_tabs(current_tab, project = nil)
        tabs = [
          { name: "general", label: :label_sla_settings, url: project ? project_sla_settings_path(project) : plugin_settings_path(id: "redmine_sla") },
          { name: "calendar", label: :label_sla_calendar, url: project ? project_sla_calendar_path(project) : redmine_sla_calendar_path },
          { name: "rules", label: :label_sla_rules, url: project ? project_sla_rules_path(project) : redmine_sla_rules_path }
        ]
        render_tabs(tabs, current_tab)
      end
    end
  end
end
