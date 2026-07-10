# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::IssueQuerySlaColumnsTest < ActiveSupport::TestCase
  def setup
    @project = Project.find(1)

    calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: calendar, wday: wday, start_minute: 540, end_minute: 1020) }
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "resolution", target_minutes: 480)

    @issue = create(:issue, project: @project)
  end

  test "exposes a sortable due_at column and a status column for every kpi" do
    query = IssueQuery.new(project: @project, name: "_")

    RedmineSla::SlaRule::KPIS.each do |kpi|
      due_at_column = query.available_columns.find { |c| c.name == :"sla_#{kpi}_due_at" }
      status_column = query.available_columns.find { |c| c.name == :"sla_#{kpi}_status" }

      assert due_at_column, "expected a sla_#{kpi}_due_at column"
      assert due_at_column.sortable?
      assert status_column, "expected a sla_#{kpi}_status column"
    end
  end

  test "sorting by a due_at column does not raise a SQL error" do
    query = IssueQuery.new(project: @project, name: "_")
    query.column_names = [ :subject, :sla_resolution_due_at ]
    query.sort_criteria = [ [ "sla_resolution_due_at", "asc" ] ]

    issues = query.issues
    assert_includes issues, @issue
  end

  test "the status column reflects the current KpiStatus classification" do
    query = IssueQuery.new(project: @project, name: "_")
    column = query.available_columns.find { |c| c.name == :sla_resolution_status }

    assert_equal I18n.t(:label_sla_status_on_time), column.value_object(@issue)
  end
end
