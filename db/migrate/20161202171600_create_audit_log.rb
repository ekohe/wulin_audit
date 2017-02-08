class CreateAuditLog < ActiveRecord::Migration[5.0]
  def change
    return if table_exists?(:audit_logs)

    create_table :audit_logs do |t|
      t.integer :user_id
      t.string  :request_ip
      t.string  :user_email
      t.string  :record_id
      t.string  :action
      t.string  :class_name
      t.jsonb   :detail
      t.timestamps
    end
    add_index :audit_logs, [:user_id, :record_id]
  end
end
