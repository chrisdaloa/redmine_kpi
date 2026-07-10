require "factory_bot"

FactoryBot::SyntaxRunner.class_eval do
  include ActionDispatch::TestProcess
  include ActiveSupport::Testing::FileFixtures
end

ActiveSupport.on_load(:active_support_test_case) { include FactoryBot::Syntax::Methods }

FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    sequence(:identifier) { |n| "project-#{n}" }
    description { "Project description" }
    homepage { "http://example.com" }
    is_public { true }
  end

  factory :sla_calendar, class: "RedmineSla::SlaCalendar" do
    project_id { nil }
  end

  factory :sla_calendar_day, class: "RedmineSla::SlaCalendarDay" do
    association :sla_calendar
    wday { 1 }
    start_minute { 9 * 60 }
    end_minute { 17 * 60 }
  end

  factory :sla_holiday, class: "RedmineSla::SlaHoliday" do
    association :sla_calendar
    date { Date.current }
    name { "Holiday" }
  end

  factory :sla_rule, class: "RedmineSla::SlaRule" do
    project_id { 0 }
    tracker_id { 0 }
    priority_id { 0 }
    kpi { "resolution" }
    target_minutes { 60 }
  end

  factory :sla_project_setting, class: "RedmineSla::SlaProjectSetting" do
    project_id { 1 }
  end

  factory :issue do
    project
    tracker { Tracker.find(1) }
    status { IssueStatus.find(1) }
    priority { IssuePriority.find(5) }
    author { User.find(2) }
    subject { "Test issue" }
    created_on { Time.zone.local(2026, 7, 1, 9, 0) }

    # Issue#force_updated_on_change forces created_on to "now" on new records,
    # so the factory's created_on has to be written after the fact. update_all
    # is used instead of update_column because Issue's own update_columns call
    # silently matches zero rows here (some scope/callback on Issue interferes
    # with instance-level updates right after insert). Reloading afterwards also
    # picks up the lock_version bump that acts_as_nested_set applies via a raw
    # UPDATE right after insert, which would otherwise leave the in-memory
    # record stale for any later #update! in the same test.
    after(:create) do |issue, evaluator|
      Issue.where(id: issue.id).update_all(created_on: evaluator.created_on)
      issue.reload
    end
  end

  factory :journal do
    association :journalized, factory: :issue
    user { User.find(1) }
    notes { "" }
    private_notes { false }
    created_on { Time.current }
  end

  factory :sla_issue_metric, class: "RedmineSla::IssueMetric" do
    association :issue
  end

  factory :journal_detail, class: "JournalDetail" do
    association :journal
    property { "attr" }
    prop_key { "status_id" }
    old_value { "1" }
    value { "2" }
  end
end
