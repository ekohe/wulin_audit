# Override `action` method to append `:authorized?` option for `:audit` action
class WulinMaster::Grid
  def self.action(a_name, options={})
    new_action = {name: a_name}.merge(options)
    # append :authorized? option
    new_action.reverse_merge!(:authorized? => lambda { |user| user.has_permission_with_name?('record_audit#read') }) if a_name.to_s == 'audit'
    self.actions_pool << new_action
    add_hotkey_action(a_name, options)
  end
end

# Add audit button to grid as default toolbar choose, set default icon from https://material.io/icons/
if WulinMaster::Grid.method(:add_default_action).parameters.size > 1
  WulinMaster::Grid.add_default_action :audit, icon: :restore
else # Support old versions of wulin_master
  WulinMaster::Grid.add_default_action :audit
end
