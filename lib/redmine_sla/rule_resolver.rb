# frozen_string_literal: true

module RedmineSla
  # Resolves the applicable target_minutes for a KPI given a project/tracker/priority
  # combination, following the precedence: project-scoped rules always win over global
  # ones, and within the same scope a tracker+priority match wins over a single-dimension
  # match, which wins over the wildcard rule.
  class RuleResolver
    PROJECT_MATCH_SCORE = 100
    TRACKER_MATCH_SCORE = 10
    PRIORITY_MATCH_SCORE = 1

    def target_minutes_for(kpi:, project_id:, tracker_id:, priority_id:)
      candidates = RedmineSla::SlaRule.where(
        kpi: kpi,
        project_id: [ project_id, 0 ],
        tracker_id: [ tracker_id, 0 ],
        priority_id: [ priority_id, 0 ]
      )
      best = candidates.max_by { |rule| score(rule, project_id, tracker_id, priority_id) }
      best&.target_minutes
    end

    private

    def score(rule, project_id, tracker_id, priority_id)
      (rule.project_id == project_id ? PROJECT_MATCH_SCORE : 0) +
        (rule.tracker_id != 0 && rule.tracker_id == tracker_id ? TRACKER_MATCH_SCORE : 0) +
        (rule.priority_id != 0 && rule.priority_id == priority_id ? PRIORITY_MATCH_SCORE : 0)
    end
  end
end
