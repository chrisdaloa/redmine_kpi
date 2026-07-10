require File.expand_path("../../../test_helper", __FILE__)

module RedmineSla
  class RecalculationsControllerTest < ActionController::TestCase
    tests RedmineSla::RecalculationsController

    context "project scope" do
      setup do
        @project = Project.find(1)
        @project.enabled_module_names += [ "sla" ]
        Role.find(1).add_permission!(:manage_sla_settings)
        @request.session[:user_id] = User.find(2).id
      end

      should "POST create trigger a bulk recalculation and redirect" do
        RedmineSla::BulkRecalculator.expects(:call)

        post :create, params: { id: @project.id }

        assert_redirected_to project_sla_settings_path(@project)
      end

      should "deny access without manage_sla_settings permission" do
        Role.find(1).remove_permission!(:manage_sla_settings)
        post :create, params: { id: @project.id }
        assert_response :forbidden
      end
    end

    context "global scope" do
      should "deny a non-admin user" do
        @request.session[:user_id] = User.find(2).id
        post :create
        assert_response :forbidden
      end

      should "POST create trigger a bulk recalculation for an admin" do
        @request.session[:user_id] = User.find(1).id
        RedmineSla::BulkRecalculator.expects(:call)

        post :create

        assert_redirected_to redmine_sla_calendar_path
      end
    end
  end
end
