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
    "pause_status_ids" => [],
    "attesa_cliente_status_ids" => [],
    "attesa_interna_status_ids" => [],
    "categoria_custom_field_id" => "",
    "responsabile_custom_field_id" => ""
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
  menu :admin_menu, :sla_admin, { controller: "settings", action: "plugin", id: "redmine_sla" },
       caption: :label_sla_configure,
       html: { class: "icon icon-settings" }
end

# Redmine's own PluginLoader already loads init.rb from within a to_prepare
# block, and re-runs it on every reload cycle in development. Wrapping this in
# another to_prepare would register a callback that only fires on the *next*
# cycle, which never happens under cache_classes (test/production) -- so it's
# applied directly here instead.
load File.join(__dir__, "lib/redmine_sla/patches/issue_patch.rb")
load File.join(__dir__, "lib/redmine_sla/patches/journal_patch.rb")
load File.join(__dir__, "lib/redmine_sla/patches/application_helper_patch.rb")
load File.join(__dir__, "lib/redmine_sla/patches/issue_query_patch.rb")

Issue.include(RedmineSla::Patches::IssuePatch) unless Issue.include?(RedmineSla::Patches::IssuePatch)
Journal.include(RedmineSla::Patches::JournalPatch) unless Journal.include?(RedmineSla::Patches::JournalPatch)
ApplicationHelper.include(RedmineSla::Patches::ApplicationHelperPatch) unless ApplicationHelper.include?(RedmineSla::Patches::ApplicationHelperPatch)
IssueQuery.prepend(RedmineSla::Patches::IssueQueryPatch) unless IssueQuery.ancestors.include?(RedmineSla::Patches::IssueQueryPatch)

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

overall_status_column_name = :sla_overall_status
unless IssueQuery.available_columns.any? { |column| column.name == overall_status_column_name }
  IssueQuery.add_available_column(
    RedmineSla::OverallStatusColumn.new(caption: :label_sla_overall_status_column)
  )
end

{
  sla_categoria: [ :categoria_custom_field_id, :label_sla_categoria ],
  sla_responsabile: [ :responsabile_custom_field_id, :label_sla_responsabile ]
}.each do |column_name, (setting_method, caption)|
  next if IssueQuery.available_columns.any? { |column| column.name == column_name }

  IssueQuery.add_available_column(
    RedmineSla::ProjectCustomFieldColumn.new(column_name, setting_method, caption: caption)
  )
end

elapsed_hours_column_name = :sla_acknowledgement_elapsed_hours
unless IssueQuery.available_columns.any? { |column| column.name == elapsed_hours_column_name }
  IssueQuery.add_available_column(
    RedmineSla::ElapsedHoursColumn.new(
      caption: :label_sla_acknowledgement_elapsed_hours,
      sortable: "(SELECT acknowledgement_elapsed_minutes FROM sla_issue_metrics WHERE sla_issue_metrics.issue_id = #{Issue.table_name}.id)"
    )
  )
end

{
  attesa_cliente: :label_sla_attesa_cliente_hours,
  attesa_interna: :label_sla_attesa_interna_hours
}.each do |kind, caption|
  column_name = :"sla_#{kind}_hours"
  next if IssueQuery.available_columns.any? { |column| column.name == column_name }

  IssueQuery.add_available_column(
    RedmineSla::AttesaHoursColumn.new(
      kind,
      caption: caption,
      sortable: "(SELECT #{kind}_minutes FROM sla_issue_metrics WHERE sla_issue_metrics.issue_id = #{Issue.table_name}.id)"
    )
  )
end

{
  acknowledgement: :label_sla_acknowledgement_progress,
  resolution: :label_sla_resolution_progress
}.each do |kpi, caption|
  column_name = :"sla_#{kpi}_progress"
  next if IssueQuery.available_columns.any? { |column| column.name == column_name }

  IssueQuery.add_available_column(RedmineSla::SlaProgressColumn.new(kpi, caption: caption))
end
