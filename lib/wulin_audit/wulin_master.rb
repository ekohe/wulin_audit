# Add audit button to every grid as default toolbar item
WulinMaster::Grid.add_default_action "audit"

WulinMaster::add_javascript 'audit.js'
WulinMaster::add_stylesheet 'audit.css'