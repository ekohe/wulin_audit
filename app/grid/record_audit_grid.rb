if defined? WulinMaster
  class RecordAuditGrid < AuditLogGrid
    title 'Record Audit Logs'

    model WulinAudit::AuditLog
    
    path '/wulin_audit/record_audits'

    cell_editable false

    action :filter

    def columns
      @columns = super.clone
      @columns.delete_if {|c| c.name.to_s =~ /^class_name$|^record_id$/}
      @columns
    end

  end
end