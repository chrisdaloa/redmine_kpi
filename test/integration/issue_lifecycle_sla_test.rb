# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::IssueLifecycleSlaTest < ActionDispatch::IntegrationTest
  def setup
    Setting.plugin_redmine_sla = {
      "risk_threshold_percent" => 80,
      "resolved_status_ids" => [ 3, 5 ],
      "pause_status_ids" => [ 4 ]
    }

    calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: calendar, wday: wday, start_minute: 540, end_minute: 1020) }

    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "acknowledgement", target_minutes: 120)
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "first_response", target_minutes: 60)
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "resolution", target_minutes: 480)
  end

  test "creating an issue automatically builds its metrics row" do
    issue = create(:issue)

    metric = RedmineSla::IssueMetric.find_by(issue_id: issue.id)
    assert_not_nil metric
    assert_not_nil metric.acknowledgement_due_at
  end

  test "a status change recalculates acknowledgement_reached_at" do
    issue = create(:issue)

    issue.init_journal(User.find(1))
    issue.update!(status: IssueStatus.find(2))

    metric = RedmineSla::IssueMetric.find_by(issue_id: issue.id)
    assert_not_nil metric.acknowledgement_reached_at
  end

  test "an unrelated attribute change does not touch already-reached metrics" do
    issue = create(:issue)
    issue.init_journal(User.find(1))
    issue.update!(status: IssueStatus.find(2))
    reached_before = RedmineSla::IssueMetric.find_by(issue_id: issue.id).acknowledgement_reached_at
    assert_not_nil reached_before

    issue.init_journal(User.find(1))
    issue.update!(subject: "Updated subject")

    reached_after = RedmineSla::IssueMetric.find_by(issue_id: issue.id).acknowledgement_reached_at
    assert_equal reached_before, reached_after
  end

  test "a tracker change recalculates due_at against the new tracker's rule" do
    issue = create(:issue, tracker: Tracker.find(1))
    create(:sla_rule, project_id: 0, tracker_id: 2, priority_id: 0, kpi: "acknowledgement", target_minutes: 30)
    due_before = RedmineSla::IssueMetric.find_by(issue_id: issue.id).acknowledgement_due_at

    issue.update!(tracker: Tracker.find(2))

    due_after = RedmineSla::IssueMetric.find_by(issue_id: issue.id).acknowledgement_due_at
    assert_not_equal due_before, due_after
  end

  test "a new public journal from another user recalculates first_response_reached_at" do
    issue = create(:issue, author: User.find(2))

    create(:journal, journalized: issue, user: User.find(1), notes: "a real response", private_notes: false)

    metric = RedmineSla::IssueMetric.find_by(issue_id: issue.id)
    assert_not_nil metric.first_response_reached_at
  end
end
