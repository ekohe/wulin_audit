if defined? WulinMaster
  class AuditLogScreen < WulinMaster::Screen
    title "Audit Log"

    path "/wulin_audit/audit_logs"

    grid AuditLogGrid
  end
end
