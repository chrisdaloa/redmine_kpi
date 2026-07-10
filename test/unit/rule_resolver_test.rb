# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::RuleResolverTest < ActiveSupport::TestCase
  context "#target_minutes_for" do
    should "return nil when no rule matches at all" do
      resolver = RedmineSla::RuleResolver.new
      assert_nil resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 1, priority_id: 1)
    end

    should "fall back to the global wildcard rule when nothing more specific matches" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 0, target_minutes: 480)
      resolver = RedmineSla::RuleResolver.new
      assert_equal 480, resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 1, priority_id: 1)
    end

    should "prefer a global tracker-specific rule over the global wildcard" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 0, target_minutes: 480)
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 2, priority_id: 0, target_minutes: 240)
      resolver = RedmineSla::RuleResolver.new
      assert_equal 240, resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 2, priority_id: 1)
    end

    should "prefer a global priority-specific rule over the global wildcard" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 0, target_minutes: 480)
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 3, target_minutes: 60)
      resolver = RedmineSla::RuleResolver.new
      assert_equal 60, resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 2, priority_id: 3)
    end

    should "prefer a global tracker+priority rule over either partial match" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 0, target_minutes: 480)
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 2, priority_id: 0, target_minutes: 240)
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 0, priority_id: 3, target_minutes: 60)
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 2, priority_id: 3, target_minutes: 30)
      resolver = RedmineSla::RuleResolver.new
      assert_equal 30, resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 2, priority_id: 3)
    end

    should "prefer any project-scoped rule over any global rule regardless of specificity" do
      create(:sla_rule, kpi: "resolution", project_id: 0, tracker_id: 2, priority_id: 3, target_minutes: 30)
      create(:sla_rule, kpi: "resolution", project_id: 1, tracker_id: 0, priority_id: 0, target_minutes: 999)
      resolver = RedmineSla::RuleResolver.new
      assert_equal 999, resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 2, priority_id: 3)
    end

    should "prefer the most specific project-scoped rule among several" do
      create(:sla_rule, kpi: "resolution", project_id: 1, tracker_id: 0, priority_id: 0, target_minutes: 999)
      create(:sla_rule, kpi: "resolution", project_id: 1, tracker_id: 2, priority_id: 3, target_minutes: 15)
      resolver = RedmineSla::RuleResolver.new
      assert_equal 15, resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 2, priority_id: 3)
    end

    should "not match a rule scoped to a different project" do
      create(:sla_rule, kpi: "resolution", project_id: 2, tracker_id: 0, priority_id: 0, target_minutes: 999)
      resolver = RedmineSla::RuleResolver.new
      assert_nil resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 2, priority_id: 3)
    end

    should "not match a rule for a different kpi" do
      create(:sla_rule, kpi: "acknowledgement", project_id: 0, tracker_id: 0, priority_id: 0, target_minutes: 30)
      resolver = RedmineSla::RuleResolver.new
      assert_nil resolver.target_minutes_for(kpi: "resolution", project_id: 1, tracker_id: 1, priority_id: 1)
    end
  end
end
