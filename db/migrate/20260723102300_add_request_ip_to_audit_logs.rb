class AddRequestIpToAuditLogs < ActiveRecord::Migration[5.0]
  def change
    return if column_exists?(:audit_logs, :request_ip)
    add_column :audit_logs, :request_ip, :string
  end
end
