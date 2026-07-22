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

  should "repopulate acknowledgement_elapsed_minutes and attesa minutes on existing data" do
    Setting.plugin_redmine_sla = Setting.plugin_redmine_sla.merge("attesa_cliente_status_ids" => [ 10 ])
    created_at = Time.zone.local(2026, 7, 1, 9, 0) # Wednesday

    issue = create(:issue, created_on: created_at)
    journal = create(:journal, journalized: issue, user: User.find(1), notes: "", created_on: created_at + 30.minutes)
    create(:journal_detail, journal: journal, property: "attr", prop_key: "status_id", old_value: "1", value: "10")
    another_journal = create(:journal, journalized: issue, user: User.find(1), notes: "", created_on: created_at + 1.hour)
    create(:journal_detail, journal: another_journal, property: "attr", prop_key: "status_id", old_value: "10", value: "1")
    issue.update_column(:status_id, 1)

    RedmineSla::BulkRecalculator.call

    metric = RedmineSla::IssueMetric.find_by(issue_id: issue.id)
    assert_equal 30, metric.acknowledgement_elapsed_minutes
    assert_equal 30, metric.attesa_cliente_minutes
    assert_nil metric.attesa_cliente_since
  end
end
