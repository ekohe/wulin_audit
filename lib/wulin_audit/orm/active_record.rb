require "wulin_audit/extension" 

class ActiveRecord::Base
  include WulinAudit::Extension
end