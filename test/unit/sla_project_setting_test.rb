# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SlaProjectSettingTest < ActiveSupport::TestCase
  context "validations" do
    should "be valid with just a project_id" do
      setting = build(:sla_project_setting)
      assert setting.valid?
    end

    should "require a project_id" do
      setting = build(:sla_project_setting, project_id: nil)
      assert_not setting.valid?
    end

    should "reject a duplicate project_id" do
      create(:sla_project_setting, project_id: 1)
      duplicate = build(:sla_project_setting, project_id: 1)
      assert_not duplicate.valid?
    end

    should "allow risk_threshold_percent to be nil (inherit global)" do
      setting = build(:sla_project_setting, risk_threshold_percent: nil)
      assert setting.valid?
    end

    should "require risk_threshold_percent to be between 0 and 100 when present" do
      setting = build(:sla_project_setting, risk_threshold_percent: 101)
      assert_not setting.valid?
    end

    should "reject a negative risk_threshold_percent" do
      setting = build(:sla_project_setting, risk_threshold_percent: -1)
      assert_not setting.valid?
    end
  end

  context "resolved_status_ids and pause_status_ids" do
    should "default to nil (inherit global) when not set" do
      setting = build(:sla_project_setting, resolved_status_ids: nil, pause_status_ids: nil)
      assert setting.valid?
      assert_nil setting.resolved_status_ids
      assert_nil setting.pause_status_ids
    end

    should "persist arrays of status ids" do
      setting = create(:sla_project_setting, resolved_status_ids: [ 3, 5 ], pause_status_ids: [ 7 ])
      setting.reload
      assert_equal [ 3, 5 ], setting.resolved_status_ids
      assert_equal [ 7 ], setting.pause_status_ids
    end
  end
end
