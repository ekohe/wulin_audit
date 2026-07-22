module WulinAudit
  class ActionLog < ::ActiveRecord::Base
    reject_audit
  end
end
