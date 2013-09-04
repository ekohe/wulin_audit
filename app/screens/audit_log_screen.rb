if defined? WulinMaster
  class AuditLogScreen < WulinMaster::Screen
    title 'Audit Logs'

    path '/wulin_audit/audit_logs'

    grid AuditLogGrid

  end
end