if defined? WulinMaster
  class RecordAuditGrid < AuditLogGrid
    title '監査ログ'

    model WulinAudit::AuditLog

    path '/wulin_audit/record_audits'

    cell_editable false

    def columns
      @columns = super.clone
      # Remove record_id but keep class_name (hidden) for translations
      @columns.delete_if {|c| c.name.to_s =~ /^record_id$/}
      # Hide class_name but keep it in the data
      class_name_col = @columns.find {|c| c.name.to_s == 'class_name'}
      class_name_col.options[:width] = 0 if class_name_col
      @columns
    end
  end
end