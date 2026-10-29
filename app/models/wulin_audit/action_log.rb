module WulinAudit
  class ActionLog < ::ActiveRecord::Base
    reject_audit

    def db_duration
      read_attribute("spans")&.dig("db", "duration")
    end

    def view_duration
      read_attribute("spans")&.dig("view", "duration")
    end

    # The remainder is unknown when db + view exceed the total: rows written
    # before the subscriber used Rails' runtimes summed nested renders, so their
    # spans overlap, and a negative "action" time would be misleading.
    def action_duration
      return unless duration
      remainder = (duration - (db_duration || 0) - (view_duration || 0)).round(2)
      remainder unless remainder.negative?
    end
  end
end
