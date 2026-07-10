# frozen_string_literal: true

module RedmineSla
  class SettingsController < ApplicationController
    before_action :find_project
    before_action :authorize

    def show
      @setting = RedmineSla::SlaProjectSetting.find_or_initialize_by(project_id: @project.id)
      @resolver = RedmineSla::SettingsResolver.new(@project.id)
    end

    def update
      @setting = RedmineSla::SlaProjectSetting.find_or_initialize_by(project_id: @project.id)
      @setting.risk_threshold_percent = params[:override_risk_threshold_percent] == "1" ? params[:risk_threshold_percent] : nil
      @setting.resolved_status_ids = params[:override_resolved_status_ids] == "1" ? Array(params[:resolved_status_ids]).compact_blank : nil
      @setting.pause_status_ids = params[:override_pause_status_ids] == "1" ? Array(params[:pause_status_ids]).compact_blank : nil

      if @setting.save
        flash[:notice] = l(:notice_successful_update)
      else
        flash[:error] = @setting.errors.full_messages.join(", ")
      end
      redirect_to project_sla_settings_path(@project)
    end

    private

    def find_project
      @project = Project.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
