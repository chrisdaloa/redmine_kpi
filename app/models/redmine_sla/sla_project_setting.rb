# frozen_string_literal: true

module RedmineSla
  class SlaProjectSetting < ApplicationRecord
    self.table_name = "sla_project_settings"

    validates :project_id, presence: true, uniqueness: true
    validates :risk_threshold_percent, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  end
end
