# Shipped once as 20260721000000, renamed in 8af3d41. Apps that migrated the
# old version already have the table, so this must survive a second run.
class CreateActionLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :action_logs, if_not_exists: true do |t|
      t.string :request_id
      t.integer :user_id
      t.string :user_email
      t.string :request_ip
      t.string :http_method
      t.string :path
      t.string :controller
      t.string :action
      t.jsonb :params
      t.integer :status
      t.float :duration
      t.integer :allocations
      t.string :exception
      t.jsonb :spans
      t.datetime :created_at

      t.index :request_id
      t.index :user_id
      t.index [:controller, :action]
      t.index :created_at
    end
  end
end
