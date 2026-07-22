# frozen_string_literal: true

module RedmineSla
  class ViewHook < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom, partial: "sla/issues/kpi_box"
    render_on :view_layouts_base_html_head, partial: "sla/html_head/stylesheet"
  end
end
