require 'mongoid'
require "wulin_audit/extension" 

module Mongoid
  module Document
    
    included do
      include WulinAudit::Extension
    end
    
  end
end