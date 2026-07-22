# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::MetricQueryColumnTest < ActiveSupport::TestCase
  def enable_sla_and_grant_view!(project)
    project.enabled_module_names += [ "sla" ]
    Role.anonymous.add_permission!(:view_sla)
  end

  context "a due_at column" do
    should "read the matching attribute off the issue's sla_metric" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(acknowledgement_due_at: Time.zone.local(2026, 7, 2, 11, 0))

      column = RedmineSla::MetricQueryColumn.new(:acknowledgement, :due_at)
      assert_equal Time.zone.local(2026, 7, 2, 11, 0), column.value_object(issue)
    end

    should "return nil when the issue has no sla_metric" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.destroy

      column = RedmineSla::MetricQueryColumn.new(:acknowledgement, :due_at)
      assert_nil column.value_object(issue.reload)
    end

    should "return nil when the sla module is disabled" do
      issue = create(:issue)
      Role.anonymous.add_permission!(:view_sla)
      issue.sla_metric.update!(acknowledgement_due_at: Time.zone.local(2026, 7, 2, 11, 0))

      column = RedmineSla::MetricQueryColumn.new(:acknowledgement, :due_at)
      assert_nil column.value_object(issue)
    end

    should "return nil when the current user lacks the view_sla permission" do
      issue = create(:issue)
      issue.project.enabled_module_names += [ "sla" ]
      issue.sla_metric.update!(acknowledgement_due_at: Time.zone.local(2026, 7, 2, 11, 0))

      column = RedmineSla::MetricQueryColumn.new(:acknowledgement, :due_at)
      assert_nil column.value_object(issue)
    end
  end

  context "a status column" do
    should "classify using RedmineSla::KpiStatus" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(
        acknowledgement_due_at: 1.hour.ago,
        acknowledgement_risk_at: 2.hours.ago,
        acknowledgement_reached_at: nil
      )

      column = RedmineSla::MetricStatusColumn.new(:acknowledgement)
      assert_equal I18n.t(:label_sla_status_breached), column.value_object(issue)
    end

    should "return the not-tracked label when there is no rule for the kpi" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)

      column = RedmineSla::MetricStatusColumn.new(:resolution)
      assert_equal I18n.t(:label_sla_status_not_tracked), column.value_object(issue)
    end

    should "return nil when the sla module is disabled" do
      issue = create(:issue)
      Role.anonymous.add_permission!(:view_sla)
      issue.sla_metric.update!(acknowledgement_due_at: 1.hour.ago, acknowledgement_risk_at: 2.hours.ago)

      column = RedmineSla::MetricStatusColumn.new(:acknowledgement)
      assert_nil column.value_object(issue)
    end

    should "return nil when the current user lacks the view_sla permission" do
      issue = create(:issue)
      issue.project.enabled_module_names += [ "sla" ]
      issue.sla_metric.update!(acknowledgement_due_at: 1.hour.ago, acknowledgement_risk_at: 2.hours.ago)

      column = RedmineSla::MetricStatusColumn.new(:acknowledgement)
      assert_nil column.value_object(issue)
    end
  end
end
