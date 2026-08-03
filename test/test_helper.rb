require "bundler/setup"
require "minitest/autorun"
require "rails"
require "active_record"
require "action_controller"
require "active_support/notifications"
require "securerandom"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :audit_logs, force: true do |t|
    t.integer :user_id
    t.string :request_ip
    t.string :user_email
    t.string :record_id
    t.string :action
    t.string :class_name
    t.json :detail
    t.timestamps
  end

  create_table :action_logs, force: true do |t|
    t.string :request_id
    t.integer :user_id
    t.string :user_email
    t.string :request_ip
    t.string :http_method
    t.string :path
    t.string :controller
    t.string :action
    t.json :params
    t.integer :status
    t.float :duration
    t.integer :allocations
    t.string :exception
    t.json :spans
    t.datetime :created_at
  end
end

# Stub the host app's current-user accessor, mirroring what WulinMaster provides.
class User
  class CurrentUser
    attr_accessor :id, :email, :ip

    def initialize(id: 1, email: "test@example.com", ip: "127.0.0.1")
      @id = id
      @email = email
      @ip = ip
    end

    def try(method)
      send(method)
    end
  end

  def self.current_user
    @current_user ||= CurrentUser.new
  end

  def self.current_user=(user)
    @current_user = user
  end
end

# Stub Rails.application so filter_params works without a full app boot.
app_config = Struct.new(:filter_parameters).new([])
Rails.instance_variable_set(:@application, Struct.new(:config).new(app_config))

require "wulin_audit"

# We don't boot a full Rails app here, so neither the engine's app/models
# autoload path nor its after_initialize hook ever runs. Load the pieces
# they'd normally wire up directly instead.
require WulinAudit::Engine.root.join("app/models/wulin_audit/audit_log").to_s
require WulinAudit::Engine.root.join("app/models/wulin_audit/action_log").to_s
require "wulin_audit/action_log_subscriber"
