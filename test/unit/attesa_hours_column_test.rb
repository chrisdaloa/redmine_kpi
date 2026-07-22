# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::AttesaHoursColumnTest < ActiveSupport::TestCase
  def enable_sla_and_grant_view!(project)
    project.enabled_module_names += [ "sla" ]
    Role.anonymous.add_permission!(:view_sla)
  end

  def setup
    @calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: @calendar, wday: wday, start_minute: 540, end_minute: 1020) }
  end

  context "an attesa hours column" do
    should "convert the stored closed-period minutes to hours when there is no open period" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(attesa_cliente_minutes: 90, attesa_cliente_since: nil)

      column = RedmineSla::AttesaHoursColumn.new(:attesa_cliente)
      assert_equal 1.5, column.value_object(issue)
    end

    should "add the live elapsed hours of a still-open period to the stored minutes" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      travel_to Time.zone.local(2026, 7, 1, 10, 0) do
        issue.sla_metric.update!(attesa_cliente_minutes: 30, attesa_cliente_since: Time.zone.local(2026, 7, 1, 9, 0))

        column = RedmineSla::AttesaHoursColumn.new(:attesa_cliente)
        assert_equal 1.5, column.value_object(issue)
      end
    end

    should "return 0 when nothing has been recorded yet" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)

      column = RedmineSla::AttesaHoursColumn.new(:attesa_cliente)
      assert_equal 0, column.value_object(issue)
    end

    should "return nil when the issue has no sla_metric" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.destroy

      column = RedmineSla::AttesaHoursColumn.new(:attesa_cliente)
      assert_nil column.value_object(issue.reload)
    end

    should "return nil when the sla module is disabled" do
      issue = create(:issue)
      Role.anonymous.add_permission!(:view_sla)
      issue.sla_metric.update!(attesa_cliente_minutes: 90)

      column = RedmineSla::AttesaHoursColumn.new(:attesa_cliente)
      assert_nil column.value_object(issue)
    end

    should "return nil when the current user lacks the view_sla permission" do
      issue = create(:issue)
      issue.project.enabled_module_names += [ "sla" ]
      issue.sla_metric.update!(attesa_cliente_minutes: 90)

      column = RedmineSla::AttesaHoursColumn.new(:attesa_cliente)
      assert_nil column.value_object(issue)
    end

    should "read the interna attributes when initialized for attesa_interna" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(attesa_interna_minutes: 120, attesa_cliente_minutes: 999)

      column = RedmineSla::AttesaHoursColumn.new(:attesa_interna)
      assert_equal 2.0, column.value_object(issue)
    end
  end
end
