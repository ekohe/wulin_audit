if defined? WulinMaster
  class RecordAuditScreen < WulinMaster::Screen
    title '監査ログ'

    path '/wulin_audit/record_audits'

    grid RecordAuditGrid

  end
end