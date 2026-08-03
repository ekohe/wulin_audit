class AddUserEmailIndexToActionLogs < ActiveRecord::Migration[5.0]
  def change
    return if index_exists?(:action_logs, :user_email)
    add_index :action_logs, :user_email
  end
end
