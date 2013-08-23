require 'mongoid'

module WulinAudit
  class AuditLog
    include Mongoid::Document
    include Mongoid::Timestamps::Created

    field :user_id, type: Integer
    field :request_ip, type: String
    field :user_email, type: String
    field :record_id, type: String
    field :action, type: String
    field :class_name, type: String
    field :detail, type: Hash

    reject_audit
  end
end
