# frozen_string_literal: true

module RedmineSla
  class SettingsController < ApplicationController
    before_action :find_project
    before_action :authorize

    def show
      @setting = RedmineSla::SlaProjectSetting.find_or_initialize_by(project_id: @project.id)
      @resolver = RedmineSla::SettingsResolver.new(@project.id)
    end

    LIST_OVERRIDE_ATTRIBUTES = %i[resolved_status_ids pause_status_ids attesa_cliente_status_ids attesa_interna_status_ids].freeze

    def update
      @setting = RedmineSla::SlaProjectSetting.find_or_initialize_by(project_id: @project.id)
      @setting.risk_threshold_percent = override?(:risk_threshold_percent) ? params[:risk_threshold_percent] : nil
      LIST_OVERRIDE_ATTRIBUTES.each { |attribute| @setting.public_send(:"#{attribute}=", list_override(attribute)) }

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

    def override?(attribute)
      params[:"override_#{attribute}"] == "1"
    end

    def list_override(attribute)
      Array(params[attribute]).compact_blank if override?(attribute)
    end
  end
end
