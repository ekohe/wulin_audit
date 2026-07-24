class AddRequestIdToAuditLogs < ActiveRecord::Migration[5.0]
  def change
    return if column_exists?(:audit_logs, :request_id)
    add_column :audit_logs, :request_id, :string
    add_index :audit_logs, :request_id
  end
end
