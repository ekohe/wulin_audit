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

# Add audit button to every grid as default toolbar item
WulinMaster::Grid.add_default_action "audit"

WulinMaster::add_javascript 'audit.js'
WulinMaster::add_stylesheet 'audit.css'