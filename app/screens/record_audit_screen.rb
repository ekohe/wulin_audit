if defined? WulinMaster
  class RecordAuditScreen < WulinMaster::Screen
    title 'Record Audit Logs'

    path '/wulin_audit/record_audits'

    grid RecordAuditGrid

  end
end