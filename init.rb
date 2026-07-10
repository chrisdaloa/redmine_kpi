$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require File.expand_path("version", __dir__)

Redmine::Plugin.register :redmine_sla do
  name "Redmine SLA plugin"
  author "chrisdaloa"
  description "This plugin adds SLA management to Redmine."
  url "https://github.com/chrisdaloa/redmine_kpi"
  author_url "https://github.com/chrisdaloa"
  requires_redmine version_or_higher: "6.0.0"

  version RedmineSla::VERSION

  settings partial: "sla_settings/global", default: {
    "risk_threshold_percent" => 80,
    "resolved_status_ids" => [],
    "pause_status_ids" => []
  }

  project_module :sla do
    permission :view_sla, {}, public: false
    permission :manage_sla_settings, {
      "redmine_sla/settings" => [ :show, :update ],
      "redmine_sla/calendars" => [ :show, :update ],
      "redmine_sla/rules" => [ :index, :create, :destroy ],
      "redmine_sla/recalculations" => [ :create ]
    }, require: :member
  end

  menu :project_menu, :sla_settings, { controller: "redmine_sla/settings", action: "show" }, caption: :label_sla
end

# Redmine's own PluginLoader already loads init.rb from within a to_prepare
# block, and re-runs it on every reload cycle in development. Wrapping this in
# another to_prepare would register a callback that only fires on the *next*
# cycle, which never happens under cache_classes (test/production) -- so it's
# applied directly here instead.
load File.join(__dir__, "lib/redmine_sla/patches/issue_patch.rb")
load File.join(__dir__, "lib/redmine_sla/patches/journal_patch.rb")

Issue.include(RedmineSla::Patches::IssuePatch) unless Issue.include?(RedmineSla::Patches::IssuePatch)
Journal.include(RedmineSla::Patches::JournalPatch) unless Journal.include?(RedmineSla::Patches::JournalPatch)

require File.join(__dir__, "lib/redmine_sla/view_hook")

RedmineSla::SlaRule::KPIS.each do |kpi|
  due_at_column_name = :"sla_#{kpi}_due_at"
  unless IssueQuery.available_columns.any? { |column| column.name == due_at_column_name }
    IssueQuery.add_available_column(
      RedmineSla::MetricQueryColumn.new(
        kpi, :due_at,
        caption: :"label_sla_kpi_#{kpi}",
        sortable: "(SELECT #{kpi}_due_at FROM sla_issue_metrics WHERE sla_issue_metrics.issue_id = #{Issue.table_name}.id)"
      )
    )
  end

  status_column_name = :"sla_#{kpi}_status"
  next if IssueQuery.available_columns.any? { |column| column.name == status_column_name }

  IssueQuery.add_available_column(
    RedmineSla::MetricStatusColumn.new(
      kpi,
      caption: -> { "#{I18n.t(:"label_sla_kpi_#{kpi}")} #{I18n.t(:label_sla_status).downcase}" }
    )
  )
end
