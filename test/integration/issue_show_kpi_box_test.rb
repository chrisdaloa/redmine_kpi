# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::IssueShowKpiBoxTest < Redmine::IntegrationTest
  def setup
    @project = Project.find(1)
    @project.enabled_module_names += [ "sla" ]

    calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: calendar, wday: wday, start_minute: 540, end_minute: 1020) }
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "resolution", target_minutes: 480)

    @issue = create(:issue, project: @project)
  end

  test "shows the kpi box when the user has the view_sla permission" do
    Role.find(1).add_permission!(:view_sla)
    log_user("jsmith", "jsmith")

    get "/issues/#{@issue.id}"

    assert_response :success
    assert_select ".sla-kpi-box"
  end

  test "hides the kpi box when the user lacks the view_sla permission" do
    log_user("jsmith", "jsmith")

    get "/issues/#{@issue.id}"

    assert_response :success
    assert_select ".sla-kpi-box", false
  end

  test "hides the kpi box when the sla module is not enabled for the project" do
    @project.enabled_module_names -= [ "sla" ]
    Role.find(1).add_permission!(:view_sla)
    log_user("jsmith", "jsmith")

    get "/issues/#{@issue.id}"

    assert_response :success
    assert_select ".sla-kpi-box", false
  end
end
