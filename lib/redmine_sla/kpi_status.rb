# frozen_string_literal: true

module RedmineSla
  # Classifies the live or final state of a single per-issue KPI, purely from the
  # timestamps stored on sla_issue_metrics. Never persisted: always recomputed at
  # render time so it can't go stale relative to the current clock.
  module KpiStatus
    PRECEDENCE = %i[breached at_risk paused on_time not_tracked].freeze

    def self.for(due_at:, risk_at:, reached_at:, paused:, now: Time.current)
      return :not_tracked if due_at.nil?
      return :paused if paused

      reference_time = reached_at || now

      if reference_time > due_at
        :breached
      elsif reference_time >= risk_at
        :at_risk
      else
        :on_time
      end
    end

    # Reduces several per-KPI statuses to the single worst one, e.g. to
    # summarize an issue's overall SLA health across all of its KPIs.
    def self.worst(statuses)
      return :not_tracked if statuses.empty?

      statuses.min_by { |status| PRECEDENCE.index(status) }
    end
  end
end
