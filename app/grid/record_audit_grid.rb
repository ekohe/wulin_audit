if defined? WulinMaster
  class RecordAuditGrid < AuditLogGrid
    title 'Record Audit Logs'
    path '/record_audits' 

    remove_actions :audit, :add, :edit, :update, :delete

    def columns
      @columns = super.clone
      @columns.delete_if {|c| c.name.to_s =~ /^class_name$|^record_id$/}
      @columns
    end

  end
end