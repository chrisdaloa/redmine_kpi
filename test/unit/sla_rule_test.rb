# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SlaRuleTest < ActiveSupport::TestCase
  context "validations" do
    should "be valid with wildcard project, tracker and priority" do
      rule = build(:sla_rule)
      assert rule.valid?
    end

    should "require a kpi" do
      rule = build(:sla_rule, kpi: nil)
      assert_not rule.valid?
    end

    should "require kpi to be one of the known KPIs" do
      rule = build(:sla_rule, kpi: "unknown_kpi")
      assert_not rule.valid?
    end

    should "require target_minutes to be a positive integer" do
      rule = build(:sla_rule, target_minutes: 0)
      assert_not rule.valid?
    end

    should "reject a duplicate rule for the same project/kpi/tracker/priority combination" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 0)
      duplicate = build(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 0)
      assert_not duplicate.valid?
    end

    should "allow the same kpi/tracker/priority combination on a different project" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 1, priority_id: 1)
      other = build(:sla_rule, kpi: "resolution", project_id: 1, tracker_id: 1, priority_id: 1)
      assert other.valid?
    end

    should "allow the same project/tracker/priority combination for a different kpi" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 1, priority_id: 1)
      other = build(:sla_rule, kpi: "first_response", project_id: 0, tracker_id: 1, priority_id: 1)
      assert other.valid?
    end
  end

  context ".kpis" do
    should "expose the three known KPI identifiers" do
      assert_equal %w[acknowledgement first_response resolution], RedmineSla::SlaRule::KPIS
    end
  end
end
