# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::BulkRecalculatorTest < ActiveSupport::TestCase
  def setup
    Setting.plugin_redmine_sla = {
      "risk_threshold_percent" => 50,
      "resolved_status_ids" => [ 3, 5 ],
      "pause_status_ids" => [ 4 ]
    }

    calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: calendar, wday: wday, start_minute: 540, end_minute: 1020) }

    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "acknowledgement", target_minutes: 120)
  end

  should "backfill a metrics row for every issue, including ones missing one" do
    issue = create(:issue)
    RedmineSla::IssueMetric.where(issue_id: issue.id).delete_all
    assert_nil RedmineSla::IssueMetric.find_by(issue_id: issue.id)

    RedmineSla::BulkRecalculator.call

    assert_not_nil RedmineSla::IssueMetric.find_by(issue_id: issue.id)
  end

  should "recompute an already-existing metrics row against the current rules" do
    issue = create(:issue)
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "first_response", target_minutes: 30)

    RedmineSla::BulkRecalculator.call

    metric = RedmineSla::IssueMetric.find_by(issue_id: issue.id)
    assert_not_nil metric.first_response_due_at
  end
end
