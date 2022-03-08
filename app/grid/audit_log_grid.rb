if defined? WulinMaster
  # require 'wulin_audit/mongoid_support'
  WulinAudit::AuditLog.class_eval do
    # include MongoidSupport

    def detail
      detail_content = read_attribute("detail")
      if Rails::VERSION::MAJOR <= 4
        detail_content = JSON.parse(detail_content)
      end
      if action == 'update'
        detail_content.map{ |change| format_detail(change) }.join(', ')
      else
        detail_content.to_s
      end
    end

    def format_detail(change)
      # change #=> ["Data", [{a: 1, b: 2, c: 3}, {a: 2, b: 2, d: 4}]]
      changed_field = change[0].titleize
      original_value = change[1][0]
      current_value = change[1][1] || {}
      return if change.blank?
      case change[1][0]
      when Hash
        # original_value #=> {a: 1, b: 2, c: 3}
        # current_value #=> {a: 2, b: 2, d: 4}
        # added_k_v #=> {d: 4}
        # removed_k_v #=> {c: 3}
        # modified_k_v #=> {a: 2} not {a: 1}
        added_k_v = current_value.select{ |k| !original_value.has_key?(k) }
        removed_k_v = original_value.select{ |k| !current_value.has_key?(k) }
        modified_k_v = current_value.select{ |k| original_value.has_key?(k) && original_value[k] != current_value[k] }

        stringified_detail = []
        added_k_v.each do |k, v|
          stringified_detail.push("'#{changed_field}[#{k}]' changed from 'NULL' to '#{v}'")
        end
        removed_k_v.each do |k, v|
          stringified_detail.push("'#{changed_field}[#{k}]' changed from '#{v}' to 'NULL'")
        end
        modified_k_v.each do |k, v|
          stringified_detail.push("'#{changed_field}[#{k}]' changed from '#{original_value[k]}' to '#{v}'")
        end
        stringified_detail.join(", ")
      else
        "'#{changed_field}' changed from '#{original_value}' to '#{current_value}'"
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
