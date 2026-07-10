require File.expand_path("../../../test_helper", __FILE__)

module RedmineSla
  class RulesControllerTest < ActionController::TestCase
    tests RedmineSla::RulesController

    context "project scope" do
      setup do
        @project = Project.find(1)
        @project.enabled_module_names += [ "sla" ]
        Role.find(1).add_permission!(:manage_sla_settings)
        @request.session[:user_id] = User.find(2).id
      end

      should "GET index render successfully" do
        get :index, params: { id: @project.id }
        assert_response :success
      end

      should "POST create persist a rule scoped to the project" do
        post :create, params: {
          id: @project.id,
          sla_rule: { kpi: "resolution", tracker_id: 0, priority_id: 0, target_minutes: 480 }
        }

        assert_redirected_to project_sla_rules_path(@project)
        rule = RedmineSla::SlaRule.find_by(project_id: @project.id, kpi: "resolution")
        assert_equal 480, rule.target_minutes
      end

      should "DELETE destroy remove a rule scoped to the project" do
        rule = RedmineSla::SlaRule.create!(project_id: @project.id, kpi: "resolution", tracker_id: 0, priority_id: 0, target_minutes: 480)

        delete :destroy, params: { id: @project.id, rule_id: rule.id }

        assert_redirected_to project_sla_rules_path(@project)
        assert_nil RedmineSla::SlaRule.find_by(id: rule.id)
      end

      should "deny access without manage_sla_settings permission" do
        Role.find(1).remove_permission!(:manage_sla_settings)
        get :index, params: { id: @project.id }
        assert_response :forbidden
      end
    end

    context "global scope" do
      should "deny a non-admin user" do
        @request.session[:user_id] = User.find(2).id
        get :index
        assert_response :forbidden
      end

      should "GET index render successfully for an admin" do
        @request.session[:user_id] = User.find(1).id
        get :index
        assert_response :success
      end

      should "render the SLA admin tabs with the rules tab selected" do
        @request.session[:user_id] = User.find(1).id
        get :index
        assert_select "div.tabs a#tab-rules.selected"
        assert_select "div.tabs a#tab-general"
        assert_select "div.tabs a#tab-calendar"
      end

      should "POST create persist a global (project_id 0) rule for an admin" do
        @request.session[:user_id] = User.find(1).id
        post :create, params: {
          sla_rule: { kpi: "acknowledgement", tracker_id: 0, priority_id: 0, target_minutes: 120 }
        }

        assert_redirected_to redmine_sla_rules_path
        rule = RedmineSla::SlaRule.find_by(project_id: 0, kpi: "acknowledgement")
        assert_equal 120, rule.target_minutes
      end
    end
  end
end
