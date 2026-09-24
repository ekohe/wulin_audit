class CreateActionLogAnalysisPermission < ActiveRecord::Migration[6.1]
  def up
    return unless defined?(Permission)

    Permission.find_or_create_by!(name: "action_log_analysis#read")
  end

  def down
    return unless defined?(Permission)

    Permission.find_by(name: "action_log_analysis#read")&.destroy
  end
end
