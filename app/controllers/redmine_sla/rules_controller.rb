# frozen_string_literal: true

module RedmineSla
  class RulesController < ApplicationController
    before_action :find_project
    before_action :authorize_rules

    def index
      @rules = RedmineSla::SlaRule.where(project_id: scope_project_id).order(:kpi, :tracker_id, :priority_id)
      @trackers = Tracker.all
      @priorities = IssuePriority.all
    end

    def create
      rule = RedmineSla::SlaRule.new(rule_params.merge(project_id: scope_project_id))
      if rule.save
        flash[:notice] = l(:notice_successful_create)
      else
        flash[:error] = rule.errors.full_messages.join(", ")
      end
      redirect_to_index
    end

    def destroy
      RedmineSla::SlaRule.where(project_id: scope_project_id, id: params[:rule_id]).destroy_all
      redirect_to_index
    end

    private

    def scope_project_id
      @project ? @project.id : 0
    end

    def find_project
      @project = Project.find(params[:id]) if params[:id]
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize_rules
      if @project
        authorize
      else
        require_admin
      end
    end

    def rule_params
      params.expect(sla_rule: [ :kpi, :tracker_id, :priority_id, :target_minutes ])
    end

    def redirect_to_index
      redirect_to(@project ? project_sla_rules_path(@project) : redmine_sla_rules_path)
    end
  end
end
