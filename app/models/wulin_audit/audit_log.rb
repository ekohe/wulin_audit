require 'mongoid'

module WulinAudit
  class AuditLog
    include Mongoid::Document
    include Mongoid::Timestamps::Created
    REJECT_AUDIT = true
  end
end
