# ceres, atlas, cruise and olatu share one action_logs table on some servers,
# so the first app to migrate adds the column and the others must skip it.
class AddHostToActionLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :action_logs, :host, :string, if_not_exists: true
    add_index :action_logs, [:host, :created_at], if_not_exists: true
  end
end
