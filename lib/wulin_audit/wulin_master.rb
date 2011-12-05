if Module.const_defined?('WulinMaster')
  WulinMaster::Toolbar.add_to_default_toolbar "Audit", :icon => 'audit'
  WulinMaster::add_javascript 'audit.js'
  WulinMaster::add_stylesheet 'audit.css'
end