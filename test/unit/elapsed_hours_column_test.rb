# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::ElapsedHoursColumnTest < ActiveSupport::TestCase
  def enable_sla_and_grant_view!(project)
    project.enabled_module_names += [ "sla" ]
    Role.anonymous.add_permission!(:view_sla)
  end

  context "an elapsed hours column" do
    should "convert acknowledgement_elapsed_minutes to hours" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(acknowledgement_elapsed_minutes: 90)

      column = RedmineSla::ElapsedHoursColumn.new
      assert_equal 1.5, column.value_object(issue)
    end

    should "return nil when acknowledgement has not been reached yet" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.update!(acknowledgement_elapsed_minutes: nil)

      column = RedmineSla::ElapsedHoursColumn.new
      assert_nil column.value_object(issue)
    end

    should "return nil when the issue has no sla_metric" do
      issue = create(:issue)
      enable_sla_and_grant_view!(issue.project)
      issue.sla_metric.destroy

      column = RedmineSla::ElapsedHoursColumn.new
      assert_nil column.value_object(issue.reload)
    end

    should "return nil when the sla module is disabled" do
      issue = create(:issue)
      Role.anonymous.add_permission!(:view_sla)
      issue.sla_metric.update!(acknowledgement_elapsed_minutes: 90)

      column = RedmineSla::ElapsedHoursColumn.new
      assert_nil column.value_object(issue)
    end

    should "return nil when the current user lacks the view_sla permission" do
      issue = create(:issue)
      issue.project.enabled_module_names += [ "sla" ]
      issue.sla_metric.update!(acknowledgement_elapsed_minutes: 90)

      column = RedmineSla::ElapsedHoursColumn.new
      assert_nil column.value_object(issue)
    end
  end
end
