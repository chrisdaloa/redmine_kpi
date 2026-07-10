class SeedDefaultSlaCalendar < ActiveRecord::Migration[7.2]
  def up
    return if RedmineSla::SlaCalendar.where(project_id: nil).exists?

    calendar = RedmineSla::SlaCalendar.create!(project_id: nil)
    (1..5).each do |wday|
      RedmineSla::SlaCalendarDay.create!(sla_calendar: calendar, wday: wday, start_minute: 9 * 60, end_minute: 17 * 60)
    end
  end

  def down
    RedmineSla::SlaCalendar.where(project_id: nil).destroy_all
  end
end
