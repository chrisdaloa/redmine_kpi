# frozen_string_literal: true

module RedmineSla
  class CalendarsController < ApplicationController
    before_action :find_project
    before_action :authorize_calendar

    def show
      @calendar = RedmineSla::SlaCalendar.find_or_initialize_by(project_id: @project&.id)
    end

    def update
      @calendar = RedmineSla::SlaCalendar.find_or_create_by!(project_id: @project&.id)

      @calendar.sla_calendar_days.destroy_all
      (params[:days] || {}).each_value do |day_params|
        next unless day_params[:enabled] == "1"

        @calendar.sla_calendar_days.create!(
          wday: day_params[:wday],
          start_minute: minutes_from_hhmm(day_params[:start]),
          end_minute: minutes_from_hhmm(day_params[:end])
        )
      end

      @calendar.sla_holidays.destroy_all
      parse_holidays(params[:holidays]).each do |date, name|
        @calendar.sla_holidays.create!(date: date, name: name)
      end

      flash[:notice] = l(:notice_successful_update)
      redirect_to(@project ? project_sla_calendar_path(@project) : redmine_sla_calendar_path)
    end

    private

    def find_project
      @project = Project.find(params[:id]) if params[:id]
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize_calendar
      if @project
        authorize
      else
        require_admin
      end
    end

    def minutes_from_hhmm(value)
      hours, minutes = value.split(":").map(&:to_i)
      (hours * 60) + minutes
    end

    def parse_holidays(text)
      text.to_s.each_line.map(&:strip).compact_blank.map do |line|
        date, name = line.split(",", 2)
        [ Date.parse(date.strip), name&.strip ]
      end
    end
  end
end
