# frozen_string_literal: true

require File.expand_path("../../test_helper", __FILE__)

class RedmineSlaAdminMenuTest < ActionController::TestCase
  tests AdminController

  test "GET index shows a link to configure SLA" do
    @request.session[:user_id] = User.find(1).id
    get :index
    assert_response :success
    assert_select "#admin-menu a[href=?]", plugin_settings_path(id: "redmine_sla"), text: I18n.t(:label_sla_configure)
  end
end
