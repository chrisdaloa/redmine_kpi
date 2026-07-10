# frozen_string_literal: true

module RedmineSla
  # Fully rebuilds the sla_issue_metrics row for a single issue from its current
  # attributes, journals, and the currently configured rules/calendar/settings.
  # Always recomputes everything from scratch: there is no incremental update path,
  # so the same code serves live event callbacks and bulk/admin recalculation alike.
  class MetricsRecalculator
    KPIS = RedmineSla::SlaRule::KPIS

    def self.call(issue)
      new(issue).call
    end

    def initialize(issue)
      @issue = issue
      @settings = RedmineSla::SettingsResolver.new(issue.project_id)
      @rule_resolver = RedmineSla::RuleResolver.new
    end

    def call
      metric = RedmineSla::IssueMetric.find_or_initialize_by(issue_id: @issue.id)

      status_changes = status_change_details
      initial_status_id = status_changes.first&.old_value.presence&.to_i || @issue.status_id
      metric.initial_status_id = initial_status_id
      metric.paused_since, metric.total_paused_minutes = pause_state(status_changes, initial_status_id)

      calendar = RedmineSla::SlaCalendar.for_project(@issue.project_id)&.business_calendar
      reached_at = {
        "acknowledgement" => status_changes.first&.journal&.created_on,
        "first_response" => first_public_response_at,
        "resolution" => resolution_reached_at(status_changes, initial_status_id)
      }

      KPIS.each do |kpi|
        assign_kpi(metric, kpi, calendar, reached_at.fetch(kpi))
      end

      metric.save!
      metric
    end

    private

    def status_change_details
      @issue.journals.includes(:details).order(:created_on, :id).flat_map(&:details)
        .select { |detail| detail.property == "attr" && detail.prop_key == "status_id" }
    end

    def first_public_response_at
      @issue.journals.order(:created_on, :id).find do |journal|
        !journal.private_notes? && journal.notes.present? && journal.user_id != @issue.author_id
      end&.created_on
    end

    def resolution_reached_at(status_changes, initial_status_id)
      resolved_ids = @settings.resolved_status_ids
      reached = resolved_ids.include?(initial_status_id) ? @issue.created_on : nil

      status_changes.each do |detail|
        was_resolved = resolved_ids.include?(detail.old_value.to_i)
        now_resolved = resolved_ids.include?(detail.value.to_i)
        if now_resolved && !was_resolved
          reached = detail.journal.created_on
        elsif !now_resolved
          reached = nil
        end
      end

      reached
    end

    def pause_state(status_changes, initial_status_id)
      pause_ids = @settings.pause_status_ids
      paused_since = pause_ids.include?(initial_status_id) ? @issue.created_on : nil
      total_paused_minutes = 0

      status_changes.each do |detail|
        was_paused = pause_ids.include?(detail.old_value.to_i)
        now_paused = pause_ids.include?(detail.value.to_i)
        if now_paused && !was_paused
          paused_since = detail.journal.created_on
        elsif !now_paused && was_paused && paused_since
          total_paused_minutes += ((detail.journal.created_on - paused_since) / 60).to_i
          paused_since = nil
        end
      end

      [ paused_since, total_paused_minutes ]
    end

    def assign_kpi(metric, kpi, calendar, reached_at)
      target = @rule_resolver.target_minutes_for(
        kpi: kpi, project_id: @issue.project_id, tracker_id: @issue.tracker_id, priority_id: @issue.priority_id
      )

      metric.public_send("#{kpi}_reached_at=", reached_at)
      metric.public_send("#{kpi}_target_minutes=", target)

      if target.nil? || calendar.nil?
        metric.public_send("#{kpi}_due_at=", nil)
        metric.public_send("#{kpi}_risk_at=", nil)
        return
      end

      pause_offset = metric.total_paused_minutes.minutes
      risk_minutes = (target * @settings.risk_threshold_percent) / 100

      metric.public_send("#{kpi}_due_at=", calendar.add_working_minutes(@issue.created_on, target) + pause_offset)
      metric.public_send("#{kpi}_risk_at=", calendar.add_working_minutes(@issue.created_on, risk_minutes) + pause_offset)
    end
  end
end
