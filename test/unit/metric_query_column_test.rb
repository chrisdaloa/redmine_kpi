# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::MetricQueryColumnTest < ActiveSupport::TestCase
  context "a due_at column" do
    should "read the matching attribute off the issue's sla_metric" do
      issue = create(:issue)
      issue.sla_metric.update!(acknowledgement_due_at: Time.zone.local(2026, 7, 2, 11, 0))

      column = RedmineSla::MetricQueryColumn.new(:acknowledgement, :due_at)
      assert_equal Time.zone.local(2026, 7, 2, 11, 0), column.value_object(issue)
    end

    should "return nil when the issue has no sla_metric" do
      issue = create(:issue)
      issue.sla_metric.destroy

      column = RedmineSla::MetricQueryColumn.new(:acknowledgement, :due_at)
      assert_nil column.value_object(issue.reload)
    end
  end

  context "a status column" do
    should "classify using RedmineSla::KpiStatus" do
      issue = create(:issue)
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

      column = RedmineSla::MetricStatusColumn.new(:resolution)
      assert_equal I18n.t(:label_sla_status_not_tracked), column.value_object(issue)
    end
  end
end
