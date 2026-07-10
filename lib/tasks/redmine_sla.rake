# frozen_string_literal: true

namespace :redmine do
  namespace :plugins do
    namespace :redmine_sla do
      desc "Recalculate SLA metrics for every issue"
      task recalculate: :environment do
        RedmineSla::BulkRecalculator.call
        puts "SLA metrics recalculated for #{Issue.count} issues."
      end
    end
  end
end
