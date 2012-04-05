require "wulin_audit/version"
require 'wulin_audit/engine' if defined? Rails

module WulinAudit; end

require 'wulin_audit/orm/active_record' if defined? ActiveRecord
require 'wulin_audit/orm/mongoid' if defined? Mongoid
require 'wulin_audit/wulin_master' if defined? ::WulinMaster
