module WulinAudit
  class AuditLog < ::ActiveRecord::Base
    reject_audit
  end
end
