# frozen_string_literal: true

module RedmineSla
  class MetricQueryColumn < QueryColumn
    def initialize(kpi, attribute, options = {})
      @kpi = kpi
      @attribute = attribute
      super(:"sla_#{kpi}_#{attribute}", options)
    end

    def value_object(issue)
      issue.sla_metric&.public_send(:"#{@kpi}_#{@attribute}")
    end
  end
end
