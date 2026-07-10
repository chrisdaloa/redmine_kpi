# frozen_string_literal: true

module RedmineSla
  class ViewHook < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom, partial: "sla/issues/kpi_box"
  end
end
