if defined? WulinMaster
  class AuditLogScreen < WulinMaster::Screen
    title 'Audit Logs'

    path '/audit_logs'

    grid AuditLogGrid

  end
end