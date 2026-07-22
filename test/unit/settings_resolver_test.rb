# frozen_string_literal: true

require_relative "../test_helper"

class RedmineSla::SettingsResolverTest < ActiveSupport::TestCase
  def setup
    Setting.plugin_redmine_sla = {
      "risk_threshold_percent" => 80,
      "resolved_status_ids" => [ 3 ],
      "pause_status_ids" => [ 4 ],
      "attesa_cliente_status_ids" => [ 5 ],
      "attesa_interna_status_ids" => [ 6 ],
      "categoria_custom_field_id" => "37",
      "responsabile_custom_field_id" => "35"
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

    should "return the global attesa_cliente_status_ids" do
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 5 ], resolver.attesa_cliente_status_ids
    end

    should "return the global attesa_interna_status_ids" do
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 6 ], resolver.attesa_interna_status_ids
    end

    should "return the global categoria_custom_field_id as an integer" do
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 37, resolver.categoria_custom_field_id
    end

    should "return the global responsabile_custom_field_id as an integer" do
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 35, resolver.responsabile_custom_field_id
    end

    should "return nil for categoria_custom_field_id when unset" do
      Setting.plugin_redmine_sla = Setting.plugin_redmine_sla.merge("categoria_custom_field_id" => "")
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_nil resolver.categoria_custom_field_id
    end

    should "coerce string ids coming from a raw form submission into integers" do
      Setting.plugin_redmine_sla = {
        "risk_threshold_percent" => "80",
        "resolved_status_ids" => [ "3", "5" ],
        "pause_status_ids" => [ "4" ],
        "attesa_cliente_status_ids" => [ "5" ],
        "attesa_interna_status_ids" => [ "6" ]
      }
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal 80, resolver.risk_threshold_percent
      assert_equal [ 3, 5 ], resolver.resolved_status_ids
      assert_equal [ 4 ], resolver.pause_status_ids
      assert_equal [ 5 ], resolver.attesa_cliente_status_ids
      assert_equal [ 6 ], resolver.attesa_interna_status_ids
    end

    should "ignore the blank placeholder entry submitted alongside an all-unchecked checkbox group" do
      Setting.plugin_redmine_sla = {
        "risk_threshold_percent" => 80,
        "resolved_status_ids" => [ "" ],
        "pause_status_ids" => [ "4" ],
        "attesa_cliente_status_ids" => [ "" ],
        "attesa_interna_status_ids" => [ "" ]
      }
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [], resolver.resolved_status_ids
      assert_equal [], resolver.attesa_cliente_status_ids
      assert_equal [], resolver.attesa_interna_status_ids
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

    should "prefer the project's attesa_cliente_status_ids over the global ones" do
      create(:sla_project_setting, project_id: 1, attesa_cliente_status_ids: [ 10 ])
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 10 ], resolver.attesa_cliente_status_ids
    end

    should "prefer the project's attesa_interna_status_ids over the global ones" do
      create(:sla_project_setting, project_id: 1, attesa_interna_status_ids: [ 11 ])
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 11 ], resolver.attesa_interna_status_ids
    end

    should "treat an explicit empty array override as no attesa statuses, not as inherit" do
      create(:sla_project_setting, project_id: 1, attesa_cliente_status_ids: [], attesa_interna_status_ids: [])
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [], resolver.attesa_cliente_status_ids
      assert_equal [], resolver.attesa_interna_status_ids
    end

    should "fall back to the global value for attesa columns the project setting leaves nil" do
      create(:sla_project_setting, project_id: 1, risk_threshold_percent: 50, attesa_cliente_status_ids: nil, attesa_interna_status_ids: nil)
      resolver = RedmineSla::SettingsResolver.new(1)
      assert_equal [ 5 ], resolver.attesa_cliente_status_ids
      assert_equal [ 6 ], resolver.attesa_interna_status_ids
    end
  end
end
