if defined? WulinMaster
  class RecordAuditScreen < WulinMaster::Screen
    title 'Record Audit Logs'

    path '/record_audits'

    grid RecordAuditGrid

  end
end