# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SettingsResolverTest < ActiveSupport::TestCase
  def setup
    Setting.plugin_redmine_sla = {
      "risk_threshold_percent" => 80,
      "resolved_status_ids" => [ 3 ],
      "pause_status_ids" => [ 4 ]
    }
  end

  context "with no per-project override" do
    should "return the global risk_threshold_percent" do
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 80, resolver.risk_threshold_percent
    end

    should "return the global resolved_status_ids" do
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 3 ], resolver.resolved_status_ids
    end

    should "return the global pause_status_ids" do
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 4 ], resolver.pause_status_ids
    end

    should "coerce string ids coming from a raw form submission into integers" do
      Setting.plugin_redmine_sla = {
        "risk_threshold_percent" => "80",
        "resolved_status_ids" => [ "3", "5" ],
        "pause_status_ids" => [ "4" ]
      }
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 80, resolver.risk_threshold_percent
      assert_equal [ 3, 5 ], resolver.resolved_status_ids
      assert_equal [ 4 ], resolver.pause_status_ids
    end

    should "ignore the blank placeholder entry submitted alongside an all-unchecked checkbox group" do
      Setting.plugin_redmine_sla = {
        "risk_threshold_percent" => 80,
        "resolved_status_ids" => [ "" ],
        "pause_status_ids" => [ "4" ]
      }
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [], resolver.resolved_status_ids
    end
  end

  context "with a per-project override" do
    should "prefer the project's risk_threshold_percent over the global one" do
      create(:sla_project_setting, project_id: 1, risk_threshold_percent: 50)
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 50, resolver.risk_threshold_percent
    end

    should "prefer the project's resolved_status_ids over the global ones" do
      create(:sla_project_setting, project_id: 1, resolved_status_ids: [ 9 ])
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 9 ], resolver.resolved_status_ids
    end

    should "treat an explicit empty array override as no resolved statuses, not as inherit" do
      create(:sla_project_setting, project_id: 1, resolved_status_ids: [])
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [], resolver.resolved_status_ids
    end

    should "fall back to the global value for a column the project setting leaves nil" do
      create(:sla_project_setting, project_id: 1, risk_threshold_percent: 50, resolved_status_ids: nil)
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 50, resolver.risk_threshold_percent
      assert_equal [ 3 ], resolver.resolved_status_ids
    end

    should "not apply another project's override" do
      create(:sla_project_setting, project_id: 2, risk_threshold_percent: 50)
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 80, resolver.risk_threshold_percent
    end

    should "coerce string ids in a project override into integers" do
      create(:sla_project_setting, project_id: 1, resolved_status_ids: [ "9" ])
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 9 ], resolver.resolved_status_ids
    end
  end
end
