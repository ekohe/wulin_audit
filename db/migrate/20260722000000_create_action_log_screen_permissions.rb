class CreateActionLogScreenPermissions < ActiveRecord::Migration[5.0]
  def up
    return unless defined?(Permission)

    Permission.find_or_create_by!(name: "action_log#read")
    Permission.find_or_create_by!(name: "action_log#cud")
  end

  def down
    return unless defined?(Permission)

    Permission.find_by(name: "action_log#read")&.destroy
    Permission.find_by(name: "action_log#cud")&.destroy
  end
end
