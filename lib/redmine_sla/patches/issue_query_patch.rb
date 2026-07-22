# frozen_string_literal: true

module RedmineSla
  module Patches
    # Adds SLA status filters (overall + one per kpi) to the issue list.
    # Needs `super` in initialize_available_filters, so this module must be
    # prepended, not included: IssueQuery already defines that method itself,
    # and a plain `include` would never let our override run.
    module IssueQueryPatch
      # Most severe first, matching RedmineSla::KpiStatus::PRECEDENCE.
      STATUSES = RedmineSla::KpiStatus::PRECEDENCE.map(&:to_s).freeze

      def initialize_available_filters
        super

        values = STATUSES.map { |status| [ I18n.t(:"label_sla_status_#{status}"), status ] }
        add_available_filter "sla_overall_status", type: :list, values: values,
          name: I18n.t(:label_sla_overall_status_column)

        RedmineSla::SlaRule::KPIS.each do |kpi|
          add_available_filter "sla_#{kpi}_status", type: :list, values: values,
            name: "#{I18n.t(:"label_sla_kpi_#{kpi}")} #{I18n.t(:label_sla_status).downcase}"
        end
      end

      def sql_for_sla_overall_status_field(_field, operator, value)
        gated_sql(operator, overall_condition(value))
      end

      RedmineSla::SlaRule::KPIS.each do |kpi|
        define_method(:"sql_for_sla_#{kpi}_status_field") do |_field, operator, value|
          gated_sql(operator, any_kpi_status_sql_for(kpi, value))
        end
      end

      private

      def gated_sql(operator, condition)
        match = operator == "=" ? condition : "NOT (#{condition})"
        "(#{Project.allowed_to_condition(User.current, :view_sla)}) AND (#{match})"
      end

      def any_kpi_status_sql_for(kpi, statuses)
        "(#{statuses.map { |status| kpi_status_sql(kpi, status) }.join(' OR ')})"
      end

      def overall_condition(statuses)
        "(#{statuses.map { |status| overall_status_sql(status) }.join(' OR ')})"
      end

      # overall == status means: no kpi is in a more severe status, and (unless
      # status is the least severe, not_tracked) at least one kpi is exactly
      # this status -- mirrors RedmineSla::KpiStatus.worst.
      def overall_status_sql(status)
        more_severe = STATUSES[0...STATUSES.index(status)]
        clauses = more_severe.map { |severe_status| "NOT (#{any_status_across_kpis_sql(severe_status)})" }
        clauses << any_status_across_kpis_sql(status) unless status == "not_tracked"
        "(#{clauses.join(' AND ')})"
      end

      def any_status_across_kpis_sql(status)
        "(#{RedmineSla::SlaRule::KPIS.map { |kpi| kpi_status_sql(kpi, status) }.join(' OR ')})"
      end

      # Mirrors RedmineSla::KpiStatus.for. Uses correlated scalar subqueries
      # instead of a join so it composes as a plain WHERE fragment, since a
      # sql_for_..._field method can only return one.
      def kpi_status_sql(kpi, status)
        due = metric_column_sql("#{kpi}_due_at")
        risk = metric_column_sql("#{kpi}_risk_at")
        paused = metric_column_sql("paused_since")
        reference = "COALESCE(#{metric_column_sql("#{kpi}_reached_at")}, #{quoted_now})"

        case status
        when "not_tracked" then "#{due} IS NULL"
        when "paused" then "#{due} IS NOT NULL AND #{paused} IS NOT NULL"
        when "breached" then "#{due} IS NOT NULL AND #{paused} IS NULL AND #{reference} > #{due}"
        when "at_risk" then "#{due} IS NOT NULL AND #{paused} IS NULL AND #{reference} <= #{due} AND #{reference} >= #{risk}"
        when "on_time" then "#{due} IS NOT NULL AND #{paused} IS NULL AND #{reference} <= #{due} AND #{reference} < #{risk}"
        end
      end

      def metric_column_sql(column)
        "(SELECT sla_m.#{column} FROM sla_issue_metrics sla_m WHERE sla_m.issue_id = #{Issue.table_name}.id)"
      end

      def quoted_now
        "'#{ActiveRecord::Base.connection.quoted_date(Time.current)}'"
      end
    end
  end
end
