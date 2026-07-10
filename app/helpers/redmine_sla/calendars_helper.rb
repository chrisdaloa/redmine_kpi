# frozen_string_literal: true

module RedmineSla
  module CalendarsHelper
    def format_minutes(minutes)
      format("%02d:%02d", minutes / 60, minutes % 60)
    end
  end
end
