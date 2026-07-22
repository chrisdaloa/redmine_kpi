# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::IssueQueryOverallStatusColumnTest < ActiveSupport::TestCase
  def setup
    @sla_project = Project.find(1)
    @sla_project.enabled_module_names += [ "sla" ]

    @other_project = create(:project)

    calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: calendar, wday: wday, start_minute: 540, end_minute: 1020) }
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "resolution", target_minutes: 480)

    @tracked_issue = create(:issue, project: @sla_project)
    @tracked_issue.sla_metric.update!(resolution_due_at: 1.hour.ago, resolution_risk_at: 2.hours.ago)

    @untracked_issue = create(:issue, project: @other_project)

    Role.find(1).add_permission!(:view_sla)
    Member.create!(project: @other_project, user: User.find(2), roles: [ Role.find(1) ])
  end

  test "exposes the overall status column exactly once" do
    query = IssueQuery.new(name: "_")

    columns = query.available_columns.select { |c| c.name == :sla_overall_status }
    assert_equal 1, columns.size
  end

  test "returns icon markup for a tracked issue in an sla-enabled project" do
    User.current = User.find_by(login: "jsmith")
    query = IssueQuery.new(name: "_")
    column = query.available_columns.find { |c| c.name == :sla_overall_status }

    value = column.value_object(@tracked_issue)

    assert value.present?
    assert value.html_safe?
  end

  test "returns nil for an issue in a project without the sla module enabled" do
    User.current = User.find_by(login: "jsmith")
    query = IssueQuery.new(name: "_")
    column = query.available_columns.find { |c| c.name == :sla_overall_status }

    assert_nil column.value_object(@untracked_issue)
  end

  test "rendering a hybrid list mixing sla and non-sla projects does not raise" do
    User.current = User.find_by(login: "jsmith")
    query = IssueQuery.new(name: "_")
    query.column_names = [ :subject, :sla_overall_status ]

    issues = query.issues
    assert_includes issues, @tracked_issue
    assert_includes issues, @untracked_issue
  end
end
