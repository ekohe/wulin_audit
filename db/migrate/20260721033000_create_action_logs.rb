class CreateActionLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :action_logs do |t|
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
    end

    add_index :action_logs, :request_id
    add_index :action_logs, :user_id
    add_index :action_logs, [:controller, :action]
    add_index :action_logs, :created_at
  end
end
