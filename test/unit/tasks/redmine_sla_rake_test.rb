require File.expand_path("../../../test_helper", __FILE__)
require "rake"

class RedmineSlaRakeTest < ActiveSupport::TestCase
  TASK_NAME = "redmine:plugins:redmine_sla:recalculate"

  setup do
    @original_rake_application = Rake.application
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
    @task = Rake::Task[TASK_NAME]

    Setting.plugin_redmine_sla = {
      "risk_threshold_percent" => 50,
      "resolved_status_ids" => [ 3, 5 ],
      "pause_status_ids" => [ 4 ]
    }

    calendar = create(:sla_calendar, project_id: nil)
    (1..5).each { |wday| create(:sla_calendar_day, sla_calendar: calendar, wday: wday, start_minute: 540, end_minute: 1020) }
    create(:sla_rule, project_id: 0, tracker_id: 0, priority_id: 0, kpi: "acknowledgement", target_minutes: 120)
  end

  teardown do
    Rake.application = @original_rake_application
  end

  context "recalculate rake task" do
    should "backfill missing metrics rows and report the issue count" do
      issue = create(:issue)
      RedmineSla::IssueMetric.where(issue_id: issue.id).delete_all

      output = capture_task_output
      assert_not_nil RedmineSla::IssueMetric.find_by(issue_id: issue.id)
      assert_match(/SLA metrics recalculated for #{Issue.count} issues\./, output)
    end
  end

  private

  def capture_task_output
    @task.reenable
    stdout = StringIO.new
    original_stdout = $stdout
    $stdout = stdout
    begin
      @task.invoke
    ensure
      $stdout = original_stdout
    end
    stdout.string
  end
end
