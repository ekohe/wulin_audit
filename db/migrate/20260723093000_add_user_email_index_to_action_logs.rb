class AddUserEmailIndexToActionLogs < ActiveRecord::Migration[5.0]
  def change
    add_index :action_logs, :user_email
  end
end
