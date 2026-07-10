require File.expand_path("../../test_helper", __FILE__)

class RedmineSlaGlobalSettingsTest < ActionController::TestCase
  tests SettingsController

  def setup
    @request.session[:user_id] = User.find(1).id
  end

  test "GET plugin renders the global sla settings partial" do
    get :plugin, params: { id: "redmine_sla" }
    assert_response :success
    assert_select "input[name=?]", "settings[risk_threshold_percent]"
  end

  test "GET plugin renders the SLA admin tabs with the general tab selected" do
    get :plugin, params: { id: "redmine_sla" }
    assert_response :success
    assert_select "div.tabs a#tab-general.selected"
    assert_select "div.tabs a#tab-calendar"
    assert_select "div.tabs a#tab-rules"
  end

  test "POST plugin persists and coerces the submitted settings" do
    post :plugin, params: {
      id: "redmine_sla",
      settings: {
        risk_threshold_percent: "70",
        resolved_status_ids: [ "", "3", "5" ],
        pause_status_ids: [ "" ]
      }
    }

    assert_redirected_to plugin_settings_path(id: "redmine_sla")
    resolver = RedmineSla::SettingsResolver.new(1)
    assert_equal 70, resolver.risk_threshold_percent
    assert_equal [ 3, 5 ], resolver.resolved_status_ids
    assert_equal [], resolver.pause_status_ids
  end
end
