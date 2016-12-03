require "wulin_audit/version"
require 'wulin_audit/engine' if defined? Rails
require 'haml-rails'

module WulinAudit; end

require 'wulin_audit/orm/active_record' if defined? ActiveRecord
# require 'wulin_audit/orm/mongoid'
require 'wulin_audit/wulin_master' if defined? ::WulinMaster
