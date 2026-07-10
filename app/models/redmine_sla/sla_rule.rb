# frozen_string_literal: true

module RedmineSla
  class SlaRule < ApplicationRecord
    self.table_name = "sla_rules"

    KPIS = %w[acknowledgement first_response resolution].freeze

    validates :kpi, inclusion: { in: KPIS }
    validates :target_minutes, numericality: { only_integer: true, greater_than: 0 }
    validates :kpi, uniqueness: { scope: [ :project_id, :tracker_id, :priority_id ] }
  end
end
