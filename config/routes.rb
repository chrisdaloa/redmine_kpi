# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  # Global/admin scope
  get "sla/calendar", to: "redmine_sla/calendars#show", as: "redmine_sla_calendar"
  post "sla/calendar", to: "redmine_sla/calendars#update"
  get "sla/rules", to: "redmine_sla/rules#index", as: "redmine_sla_rules"
  post "sla/rules", to: "redmine_sla/rules#create"
  delete "sla/rules/:rule_id", to: "redmine_sla/rules#destroy", as: "redmine_sla_rule"
  post "sla/recalculate", to: "redmine_sla/recalculations#create", as: "redmine_sla_recalculation"

  # Per-project scope
  get "projects/:id/sla/settings", to: "redmine_sla/settings#show", as: "project_sla_settings"
  post "projects/:id/sla/settings", to: "redmine_sla/settings#update"
  get "projects/:id/sla/calendar", to: "redmine_sla/calendars#show", as: "project_sla_calendar"
  post "projects/:id/sla/calendar", to: "redmine_sla/calendars#update"
  get "projects/:id/sla/rules", to: "redmine_sla/rules#index", as: "project_sla_rules"
  post "projects/:id/sla/rules", to: "redmine_sla/rules#create"
  delete "projects/:id/sla/rules/:rule_id", to: "redmine_sla/rules#destroy", as: "project_sla_rule"
  post "projects/:id/sla/recalculate", to: "redmine_sla/recalculations#create", as: "project_sla_recalculation"
end
