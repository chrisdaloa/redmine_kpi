# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SlaProgressColumnTest < ActiveSupport::TestCase
  def enable_sla_and_grant_view!(project)
    project.enabled_module_names += [ "sla" ]
    Role.anonymous.add_permission!(:view_sla)
  end

  def setup
    @calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: @calendar, wday: wday, start_minute: 540, end_minute: 1020) }
  end

  def issue_with_metric(**attrs)
    issue = create(:issue, created_on: Time.zone.local(2026, 7, 1, 9, 0))
    enable_sla_and_grant_view!(issue.project)
    issue.sla_metric.update!(attrs)
    issue
  end

  context "a pending kpi" do
    should "show a colored progress bar with the elapsed/target percentage computed against now" do
      issue = issue_with_metric(
        acknowledgement_target_minutes: 120,
        acknowledgement_due_at: Time.zone.local(2026, 7, 1, 12, 0),
        acknowledgement_risk_at: Time.zone.local(2026, 7, 1, 11, 0)
      )

      travel_to Time.zone.local(2026, 7, 1, 10, 0) do
        column = RedmineSla::SlaProgressColumn.new(:acknowledgement)
        html = column.value_object(issue)

        assert html.html_safe?
        assert_includes html, "sla-progress-on_time"
        assert_includes html, "width: 50%;"
        assert_includes html, "title=\"#{I18n.t(:label_sla_status_on_time)}\""
        assert_includes html, ">50%<"
      end
    end

    should "cap the visual bar width at 100% when the kpi is over target, while still showing the real percentage" do
      issue = issue_with_metric(
        acknowledgement_target_minutes: 60,
        acknowledgement_due_at: Time.zone.local(2026, 7, 1, 10, 0),
        acknowledgement_risk_at: Time.zone.local(2026, 7, 1, 9, 45)
      )

      travel_to Time.zone.local(2026, 7, 1, 13, 0) do
        column = RedmineSla::SlaProgressColumn.new(:acknowledgement)
        html = column.value_object(issue)

        assert_includes html, "sla-progress-breached"
        assert_includes html, "width: 100%;"
        assert_includes html, "title=\"#{I18n.t(:label_sla_status_breached)}\""
        assert_includes html, ">400%<"
      end
    end
  end

  context "a reached kpi" do
    should "compute the percentage against the elapsed time to reached_at, not now" do
      issue = issue_with_metric(
        acknowledgement_target_minutes: 120,
        acknowledgement_due_at: Time.zone.local(2026, 7, 1, 12, 0),
        acknowledgement_risk_at: Time.zone.local(2026, 7, 1, 11, 0),
        acknowledgement_reached_at: Time.zone.local(2026, 7, 1, 10, 0)
      )

      travel_to Time.zone.local(2026, 7, 1, 16, 0) do
        column = RedmineSla::SlaProgressColumn.new(:acknowledgement)
        html = column.value_object(issue)

        assert_includes html, "sla-progress-on_time"
        assert_includes html, "title=\"#{I18n.t(:label_sla_status_on_time)}\""
        assert_includes html, ">50%<"
      end
    end
  end

  context "a paused kpi" do
    should "show a grey progress bar" do
      issue = issue_with_metric(
        acknowledgement_target_minutes: 120,
        acknowledgement_due_at: Time.zone.local(2026, 7, 1, 12, 0),
        acknowledgement_risk_at: Time.zone.local(2026, 7, 1, 11, 0),
        paused_since: Time.zone.local(2026, 7, 1, 10, 0)
      )

      travel_to Time.zone.local(2026, 7, 1, 10, 0) do
        column = RedmineSla::SlaProgressColumn.new(:acknowledgement)
        html = column.value_object(issue)

        assert_includes html, "sla-progress-paused"
      end
    end
  end

  context "not tracked" do
    should "show only the not-tracked label, with no percentage" do
      issue = issue_with_metric(acknowledgement_target_minutes: nil, acknowledgement_due_at: nil)

      column = RedmineSla::SlaProgressColumn.new(:acknowledgement)
      assert_equal I18n.t(:label_sla_status_not_tracked), column.value_object(issue)
    end
  end

  context "permissions" do
    should "return nil when the sla module is disabled" do
      issue = create(:issue)
      Role.anonymous.add_permission!(:view_sla)

      column = RedmineSla::SlaProgressColumn.new(:acknowledgement)
      assert_nil column.value_object(issue)
    end

    should "return nil when the current user lacks the view_sla permission" do
      issue = create(:issue)
      issue.project.enabled_module_names += [ "sla" ]

      column = RedmineSla::SlaProgressColumn.new(:acknowledgement)
      assert_nil column.value_object(issue)
    end
  end
end
