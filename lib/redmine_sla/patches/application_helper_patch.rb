# frozen_string_literal: true

module RedmineSla
  module Patches
    module ApplicationHelperPatch
      def sla_admin_tabs(current_tab)
        tabs = [
          { name: "general", label: :label_sla_settings, url: plugin_settings_path(id: "redmine_sla") },
          { name: "calendar", label: :label_sla_calendar, url: redmine_sla_calendar_path },
          { name: "rules", label: :label_sla_rules, url: redmine_sla_rules_path }
        ]
        render_tabs(tabs, current_tab)
      end
    end
  end
end
