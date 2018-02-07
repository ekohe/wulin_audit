if defined? WulinMaster
  # require 'wulin_audit/mongoid_support'
  WulinAudit::AuditLog.class_eval do
    # include MongoidSupport

    def detail
      detail_hash = read_attribute("detail")
      if Rails::VERSION::MAJOR <= 4
        detail_hash = JSON.parse(detail_hash)
      end
      if action == 'update'
        detail_hash.inject([]){|d, h| d << "'#{h[0].titleize}' changed from '#{h[1][0]}'  to '#{h[1][1]}'" }.join(', ')
      else
        detail_hash.to_s
      end
    end
  end

  class AuditLogGrid < WulinMaster::Grid
    title 'Audit Logs'

    model WulinAudit::AuditLog

    cell_editable false

    path '/wulin_audit/audit_logs'

    column :created_at, :width => 150, :label => 'Datetime', :type => 'Datetime', :datetime_format => :db
    column :user_email, :width => 150, :label => 'User'
    column :action, :width => 80
    column :class_name, :width => 150, :label => 'Class'
    column :record_id, :width => 70, :label => 'Id'
    column :request_ip, :width => 150, :label => 'IP'
    column :detail, :width => 500

    if defined? WulinMaster::GridActions::ORIGINAL_ACTIONS
      action :excel
      action :filter
    else
      action :export
    end
  end
end
