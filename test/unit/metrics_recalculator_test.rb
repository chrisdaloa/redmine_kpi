# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::MetricsRecalculatorTest < ActiveSupport::TestCase
  def local(*args)
    Time.zone.local(*args)
  end

  def created_at
    local(2026, 7, 1, 9, 0) # Wednesday
  end

  def setup
    Setting.plugin_redmine_sla = {
      "risk_threshold_percent" => 50,
      "resolved_status_ids" => [ 3, 5 ],
      "pause_status_ids" => [ 4 ]
    }

    calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: calendar, wday: wday, start_minute: 540, end_minute: 1020) }

    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "acknowledgement", target_minutes: 120)
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "first_response", target_minutes: 60)
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "resolution", target_minutes: 480)
  end

  def status_change(issue, at:, from:, to:)
    journal = create(:journal, journalized: issue, user: User.find(1), notes: "", created_on: at)
    create(:journal_detail, journal: journal, property: "attr", prop_key: "status_id", old_value: from.to_s, value: to.to_s)
    journal
  end

  def recalculate(issue)
    RedmineSla::MetricsRecalculator.call(issue)
  end

  context "a freshly created issue with no journals" do
    should "compute due_at/risk_at for every KPI from the creation time, with nothing reached yet" do
      issue = create(:issue, created_on: created_at)

      metric = recalculate(issue)

      assert_nil metric.acknowledgement_reached_at
      assert_equal local(2026, 7, 1, 11, 0), metric.acknowledgement_due_at
      assert_equal local(2026, 7, 1, 10, 0), metric.acknowledgement_risk_at

      assert_nil metric.first_response_reached_at
      assert_equal local(2026, 7, 1, 10, 0), metric.first_response_due_at
      assert_equal local(2026, 7, 1, 9, 30), metric.first_response_risk_at

      assert_nil metric.resolution_reached_at
      assert_equal local(2026, 7, 1, 17, 0), metric.resolution_due_at
      assert_equal local(2026, 7, 1, 13, 0), metric.resolution_risk_at

      assert_equal issue.status_id, metric.initial_status_id
      assert_nil metric.paused_since
      assert_equal 0, metric.total_paused_minutes
    end
  end

  context "the first status change" do
    should "set acknowledgement_reached_at and initial_status_id from it, while due_at stays the full target" do
      issue = create(:issue, created_on: created_at)
      status_change(issue, at: local(2026, 7, 1, 10, 0), from: 1, to: 2)
      issue.update_column(:status_id, 2)

      metric = recalculate(issue)

      assert_equal 1, metric.initial_status_id
      assert_equal local(2026, 7, 1, 10, 0), metric.acknowledgement_reached_at
      assert_equal local(2026, 7, 1, 11, 0), metric.acknowledgement_due_at
    end
  end

  context "first public response detection" do
    should "ignore private notes, blank notes and the author's own notes, counting only the first qualifying one" do
      issue = create(:issue, created_on: created_at, author: User.find(2))

      create(:journal, journalized: issue, user: User.find(1), notes: "private one", private_notes: true, created_on: local(2026, 7, 1, 9, 30))
      create(:journal, journalized: issue, user: User.find(1), notes: "", private_notes: false, created_on: local(2026, 7, 1, 9, 45))
      create(:journal, journalized: issue, user: User.find(2), notes: "self note", private_notes: false, created_on: local(2026, 7, 1, 10, 0))
      create(:journal, journalized: issue, user: User.find(1), notes: "real response", private_notes: false, created_on: local(2026, 7, 1, 10, 15))
      create(:journal, journalized: issue, user: User.find(3), notes: "later response", private_notes: false, created_on: local(2026, 7, 1, 11, 0))

      metric = recalculate(issue)

      assert_equal local(2026, 7, 1, 10, 15), metric.first_response_reached_at
    end
  end

  context "a resolve -> reopen -> reclose cycle" do
    should "clear resolution_reached_at on reopening and set it again from the later reclose" do
      issue = create(:issue, created_on: created_at)

      status_change(issue, at: local(2026, 7, 1, 9, 30), from: 1, to: 3)
      status_change(issue, at: local(2026, 7, 1, 10, 0), from: 3, to: 4)
      status_change(issue, at: local(2026, 7, 1, 10, 30), from: 4, to: 5)
      issue.update_column(:status_id, 5)

      metric = recalculate(issue)

      assert_equal local(2026, 7, 1, 10, 30), metric.resolution_reached_at
    end

    should "leave resolution_reached_at nil while the issue is currently reopened" do
      issue = create(:issue, created_on: created_at)

      status_change(issue, at: local(2026, 7, 1, 9, 30), from: 1, to: 3)
      status_change(issue, at: local(2026, 7, 1, 10, 0), from: 3, to: 4)
      issue.update_column(:status_id, 4)

      metric = recalculate(issue)

      assert_nil metric.resolution_reached_at
    end
  end

  context "multiple pause episodes" do
    should "accumulate wall-clock minutes from completed episodes and shift due_at, leaving paused_since nil once closed" do
      issue = create(:issue, created_on: created_at)

      status_change(issue, at: local(2026, 7, 1, 9, 30), from: 1, to: 4)
      status_change(issue, at: local(2026, 7, 1, 10, 0), from: 4, to: 2)
      status_change(issue, at: local(2026, 7, 1, 11, 0), from: 2, to: 4)
      status_change(issue, at: local(2026, 7, 1, 11, 20), from: 4, to: 2)
      issue.update_column(:status_id, 2)

      metric = recalculate(issue)

      assert_equal 50, metric.total_paused_minutes
      assert_nil metric.paused_since
      assert_equal local(2026, 7, 1, 11, 50), metric.acknowledgement_due_at
    end

    should "not shift due_at for the elapsed time of a still-open pause episode" do
      issue = create(:issue, created_on: created_at)

      status_change(issue, at: local(2026, 7, 1, 9, 30), from: 1, to: 4)
      issue.update_column(:status_id, 4)

      metric = recalculate(issue)

      assert_equal local(2026, 7, 1, 9, 30), metric.paused_since
      assert_equal 0, metric.total_paused_minutes
      assert_equal local(2026, 7, 1, 11, 0), metric.acknowledgement_due_at
    end
  end

  context "no calendar configured" do
    should "leave due_at/risk_at nil instead of raising, just like a missing rule" do
      RedmineSla::SlaCalendar.destroy_all

      issue = create(:issue, created_on: created_at)
      metric = recalculate(issue)

      assert_nil metric.acknowledgement_due_at
      assert_nil metric.acknowledgement_risk_at
      assert_equal 120, metric.acknowledgement_target_minutes
    end
  end

  context "a tracker change" do
    should "recompute due_at against the rule for the new tracker" do
      issue = create(:issue, created_on: created_at, tracker: Tracker.find(1))
      create(:sla_rule, project_id: 0, tracker_id: 2, priority_id: 0, kpi: "acknowledgement", target_minutes: 30)

      first_metric = recalculate(issue)
      assert_equal local(2026, 7, 1, 11, 0), first_metric.acknowledgement_due_at

      issue.update_column(:tracker_id, 2)
      second_metric = recalculate(issue)

      assert_equal local(2026, 7, 1, 9, 30), second_metric.acknowledgement_due_at
    end
  end
end
