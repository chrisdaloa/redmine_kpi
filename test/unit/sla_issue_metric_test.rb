# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::IssueMetricTest < ActiveSupport::TestCase
  context "validations" do
    should "be valid with an issue" do
      issue = create(:issue)
      RedmineSla::IssueMetric.find_by(issue_id: issue.id).destroy

      metric = build(:sla_issue_metric, issue: issue)
      assert metric.valid?
    end

    should "require an issue_id" do
      metric = build(:sla_issue_metric, issue: nil)
      assert_not metric.valid?
    end

    should "reject a second metrics row for the same issue" do
      issue = create(:issue)

      duplicate = build(:sla_issue_metric, issue: issue)
      assert_not duplicate.valid?
    end
  end

  context "associations" do
    should "belong to its issue" do
      issue = create(:issue)
      metric = RedmineSla::IssueMetric.find_by(issue_id: issue.id)
      assert_equal issue, metric.issue
    end
  end
end
