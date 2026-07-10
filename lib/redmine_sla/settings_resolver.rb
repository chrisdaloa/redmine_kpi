# frozen_string_literal: true

module RedmineSla
  # Resolves the effective scalar SLA settings for a project, falling back from a
  # per-project override (sla_project_settings, nil column = inherit) to the global
  # plugin settings (Setting.plugin_redmine_sla).
  class SettingsResolver
    def initialize(project_id)
      @project_id = project_id
    end

    def risk_threshold_percent
      (project_setting&.risk_threshold_percent || global_settings["risk_threshold_percent"]).to_i
    end

    def resolved_status_ids
      normalize_ids(project_setting&.resolved_status_ids || global_settings["resolved_status_ids"])
    end

    def pause_status_ids
      normalize_ids(project_setting&.pause_status_ids || global_settings["pause_status_ids"])
    end

    private

    def normalize_ids(ids)
      (ids || []).compact_blank.map(&:to_i)
    end

    def project_setting
      return @project_setting if defined?(@project_setting)

      @project_setting = RedmineSla::SlaProjectSetting.find_by(project_id: @project_id)
    end

    def global_settings
      Setting.plugin_redmine_sla || {}
    end
  end
end
