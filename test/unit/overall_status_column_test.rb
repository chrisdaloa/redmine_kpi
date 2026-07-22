# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::OverallStatusColumnTest < ActiveSupport::TestCase
  def setup
    @column = RedmineSla::OverallStatusColumn.new
  end

  def enable_sla_and_grant_view!(project)
    project.enabled_module_names += [ "sla" ]
    Role.anonymous.add_permission!(:view_sla)
  end

  context "#value_object" do
    should "return nil when the issue has no sla_metric" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.destroy

      assert_nil @column.value_object(issue.reload)
    end

    should "return nil when no kpi has a matching rule" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)

      assert_nil @column.value_object(issue)
    end

    should "return html-safe icon markup for a breached kpi" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(resolution_due_at: 1.hour.ago, resolution_risk_at: 2.hours.ago)

      value = @column.value_object(issue)

      assert value.html_safe?
      assert_includes value, "icon--close"
    end

    should "return the checked icon when every tracked kpi is on time" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(resolution_due_at: 1.hour.from_now, resolution_risk_at: 30.minutes.from_now)

      value = @column.value_object(issue)

      assert value.html_safe?
      assert_includes value, "icon--checked"
    end

    should "return the paused icon when the worst kpi is paused" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(
        resolution_due_at: 1.hour.from_now,
        resolution_risk_at: 30.minutes.from_now,
        paused_since: Time.current
      )

      value = @column.value_object(issue)

      assert value.html_safe?
      assert_includes value, "icon--time"
    end

    should "return nil when the sla module is disabled even though a rule matched" do
      issue = create(:issue)
      Role.anonymous.add_permission!(:view_sla)
      issue.sla_metric.update!(resolution_due_at: 1.hour.ago, resolution_risk_at: 2.hours.ago)

      assert_nil @column.value_object(issue)
    end

    should "return nil when the current user lacks the view_sla permission" do
      issue = create(:issue)
      issue.project.enabled_module_names += [ "sla" ]
      issue.sla_metric.update!(resolution_due_at: 1.hour.ago, resolution_risk_at: 2.hours.ago)

      assert_nil @column.value_object(issue)
    end
  end
end
