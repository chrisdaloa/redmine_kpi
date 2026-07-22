require File.expand_path("../../../test_helper", __FILE__)

module RedmineSla
  class CalendarsControllerTest < ActionController::TestCase
    tests RedmineSla::CalendarsController

    context "project scope" do
      setup do
        @project = Project.find(1)
        @project.enabled_module_names += [ "sla" ]
        Role.find(1).add_permission!(:manage_sla_settings)
        @request.session[:user_id] = User.find(2).id
      end

      should "GET show render successfully" do
        get :show, params: { id: @project.id }
        assert_response :success
      end

      should "POST update persist working days and holidays for the project" do
        post :update, params: {
          id: @project.id,
          days: {
            "1" => { wday: "1", enabled: "1", start: "08:00", end: "12:00" }
          },
          holidays: "2026-12-25,Christmas"
        }

        assert_redirected_to project_sla_calendar_path(@project)
        calendar = RedmineSla::SlaCalendar.find_by(project_id: @project.id)
        assert_equal 1, calendar.sla_calendar_days.count
        day = calendar.sla_calendar_days.first
        assert_equal 1, day.wday
        assert_equal 480, day.start_minute
        assert_equal 720, day.end_minute
        assert_equal 1, calendar.sla_holidays.count
        assert_equal "Christmas", calendar.sla_holidays.first.name
      end

      should "POST update persist a lunch break when both break times are given" do
        post :update, params: {
          id: @project.id,
          days: {
            "1" => { wday: "1", enabled: "1", start: "09:00", end: "18:00", break_start: "13:00", break_end: "14:00" }
          },
          holidays: ""
        }

        day = RedmineSla::SlaCalendar.find_by(project_id: @project.id).sla_calendar_days.first
        assert_equal 780, day.break_start_minute
        assert_equal 840, day.break_end_minute
      end

      should "POST update leave the break unset when the break fields are blank" do
        post :update, params: {
          id: @project.id,
          days: {
            "1" => { wday: "1", enabled: "1", start: "09:00", end: "18:00", break_start: "", break_end: "" }
          },
          holidays: ""
        }

        day = RedmineSla::SlaCalendar.find_by(project_id: @project.id).sla_calendar_days.first
        assert_nil day.break_start_minute
        assert_nil day.break_end_minute
      end

      should "deny access without manage_sla_settings permission" do
        Role.find(1).remove_permission!(:manage_sla_settings)
        get :show, params: { id: @project.id }
        assert_response :forbidden
      end
    end

    context "global scope" do
      should "deny a non-admin user" do
        @request.session[:user_id] = User.find(2).id
        get :show
        assert_response :forbidden
      end

      should "GET show render successfully for an admin" do
        @request.session[:user_id] = User.find(1).id
        get :show
        assert_response :success
      end

      should "render the SLA admin tabs with the calendar tab selected" do
        @request.session[:user_id] = User.find(1).id
        get :show
        assert_select "div.tabs a#tab-calendar.selected"
        assert_select "div.tabs a#tab-general"
        assert_select "div.tabs a#tab-rules"
      end
    end
  end
end
