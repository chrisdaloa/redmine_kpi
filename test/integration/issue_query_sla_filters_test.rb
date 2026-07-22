# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::IssueQuerySlaFiltersTest < ActiveSupport::TestCase
  NOW = Time.zone.local(2026, 7, 1, 12, 0)

  def setup
    @project = Project.find(1)
    @project.enabled_module_names += [ "sla" ]
    Role.anonymous.add_permission!(:view_sla)

    @other_project = create(:project)

    @on_time = issue_with_ack(due_at: NOW + 2.hours, risk_at: NOW + 1.hour)
    @at_risk = issue_with_ack(due_at: NOW + 2.hours, risk_at: NOW)
    @breached = issue_with_ack(due_at: NOW - 1.hour, risk_at: NOW - 2.hours)
    @paused = issue_with_ack(due_at: NOW + 2.hours, risk_at: NOW + 1.hour, paused_since: NOW - 30.minutes)
    @not_tracked = issue_with_ack(due_at: nil, risk_at: nil)

    @unpermitted = create(:issue, project: @other_project)
    @unpermitted.sla_metric.update!(acknowledgement_due_at: NOW - 1.hour, acknowledgement_risk_at: NOW - 2.hours)
  end

  def issue_with_ack(due_at:, risk_at:, paused_since: nil)
    issue = create(:issue, project: @project)
    issue.sla_metric.update!(acknowledgement_due_at: due_at, acknowledgement_risk_at: risk_at, paused_since: paused_since)
    issue
  end

  def issues_for(field, operator, value)
    travel_to(NOW) do
      query = IssueQuery.new(name: "_")
      query.add_filter(field, operator, value)
      query.issues
    end
  end

  context "the per-kpi status filter" do
    should "match only issues classified as breached" do
      issues = issues_for("sla_acknowledgement_status", "=", [ "breached" ])

      assert_includes issues, @breached
      assert_not_includes issues, @on_time
      assert_not_includes issues, @at_risk
      assert_not_includes issues, @paused
      assert_not_includes issues, @not_tracked
    end

    should "match only issues classified as at_risk" do
      issues = issues_for("sla_acknowledgement_status", "=", [ "at_risk" ])

      assert_includes issues, @at_risk
      assert_not_includes issues, @breached
    end

    should "match only issues classified as paused" do
      issues = issues_for("sla_acknowledgement_status", "=", [ "paused" ])

      assert_includes issues, @paused
      assert_not_includes issues, @on_time
    end

    should "match only issues classified as not_tracked" do
      issues = issues_for("sla_acknowledgement_status", "=", [ "not_tracked" ])

      assert_includes issues, @not_tracked
      assert_not_includes issues, @on_time
    end

    should "exclude an issue in a project without the sla module enabled, even though it would match" do
      issues = issues_for("sla_acknowledgement_status", "=", [ "breached" ])

      assert_not_includes issues, @unpermitted
    end

    should "with the negative operator, exclude matches but never leak unpermitted projects' issues" do
      issues = issues_for("sla_acknowledgement_status", "!", [ "breached" ])

      assert_includes issues, @on_time
      assert_not_includes issues, @breached
      assert_not_includes issues, @unpermitted
    end
  end

  context "the overall status filter" do
    should "classify an issue by the worst status across its kpis" do
      issue = create(:issue, project: @project)
      issue.sla_metric.update!(
        acknowledgement_due_at: NOW + 2.hours, acknowledgement_risk_at: NOW + 1.hour,
        resolution_due_at: NOW - 1.hour, resolution_risk_at: NOW - 2.hours
      )

      issues = issues_for("sla_overall_status", "=", [ "breached" ])

      assert_includes issues, issue
    end

    should "classify an issue with only not_tracked kpis as not_tracked" do
      issues = issues_for("sla_overall_status", "=", [ "not_tracked" ])

      assert_includes issues, @not_tracked
    end

    should "not classify an issue with one on_time kpi and the rest not_tracked as not_tracked" do
      issues = issues_for("sla_overall_status", "=", [ "not_tracked" ])

      assert_not_includes issues, @on_time
    end

    should "classify that same issue as on_time overall" do
      issues = issues_for("sla_overall_status", "=", [ "on_time" ])

      assert_includes issues, @on_time
    end
  end
end
