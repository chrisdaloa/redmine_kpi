require File.expand_path("../../../test_helper", __FILE__)

module RedmineSla
  class SettingsControllerTest < ActionController::TestCase
    tests RedmineSla::SettingsController

    def setup
      @project = Project.find(1)
      @project.enabled_module_names += [ "sla" ]
      @user = User.find(2)
      Role.find(1).add_permission!(:manage_sla_settings)
      @request.session[:user_id] = @user.id
    end

    test "GET show renders successfully" do
      get :show, params: { id: @project.id }
      assert_response :success
    end

    test "POST update with overrides enabled persists a project override" do
      post :update, params: {
        id: @project.id,
        override_risk_threshold_percent: "1",
        risk_threshold_percent: "60",
        override_resolved_status_ids: "1",
        resolved_status_ids: [ "3", "5" ],
        override_pause_status_ids: "0"
      }

      assert_redirected_to project_sla_settings_path(@project)
      setting = RedmineSla::SlaProjectSetting.find_by(project_id: @project.id)
      assert_equal 60, setting.risk_threshold_percent
      assert_equal [ 3, 5 ], setting.resolved_status_ids.map(&:to_i)
      assert_nil setting.pause_status_ids
    end

    test "a user without manage_sla_settings permission is denied" do
      Role.find(1).remove_permission!(:manage_sla_settings)
      get :show, params: { id: @project.id }
      assert_response :forbidden
    end
  end
end
