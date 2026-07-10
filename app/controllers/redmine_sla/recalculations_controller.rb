# frozen_string_literal: true

module RedmineSla
  class RecalculationsController < ApplicationController
    before_action :find_project
    before_action :authorize_recalculation

    def create
      RedmineSla::BulkRecalculator.call
      flash[:notice] = l(:notice_sla_recalculation_scheduled)
      redirect_to(@project ? project_sla_settings_path(@project) : redmine_sla_calendar_path)
    end

    private

    def find_project
      @project = Project.find(params[:id]) if params[:id]
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize_recalculation
      if @project
        authorize
      else
        require_admin
      end
    end
  end
end
