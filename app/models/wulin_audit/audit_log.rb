require 'mongoid'

module WulinAudit
  class AuditLog
    include Mongoid::Document
    include Mongoid::Timestamps::Created
    reject_audit
  end
end
