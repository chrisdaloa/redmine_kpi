# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::IssuePatchTest < ActiveSupport::TestCase
  context "sla_metric association" do
    should "return the automatically created metrics row" do
      issue = create(:issue)
      metric = RedmineSla::IssueMetric.find_by(issue_id: issue.id)

      assert_equal metric, issue.sla_metric
    end

    should "return nil when no metrics row exists" do
      issue = create(:issue)
      RedmineSla::IssueMetric.find_by(issue_id: issue.id).destroy

      assert_nil issue.reload.sla_metric
    end
  end
end
