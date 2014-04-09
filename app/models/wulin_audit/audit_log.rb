module WulinAudit
  class AuditLog < ::ActiveRecord::Base
    reject_audit

    index :created_at
    index :user_email
    index :action
    index :class_name
    index :record_id
    index :request_ip
    index :detail
  end
end
