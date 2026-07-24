module WulinAudit
  class ActionLog < ::ActiveRecord::Base
    reject_audit

    def db_duration
      read_attribute("spans")&.dig("db", "duration")
    end

    def view_duration
      read_attribute("spans")&.dig("view", "duration")
    end

    def action_duration
      return unless duration
      (duration - (db_duration || 0) - (view_duration || 0)).round(2)
    end
  end
end
