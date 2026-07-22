require "rails"

module WulinAudit
  class Engine < Rails::Engine
    engine_name :wulin_audit

    initializer "add assets to precompile" do |app|
      app.config.assets.precompile += %w[audit.css audit.js audit.png]
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "wulin_audit.reject_action_log" do
      ActiveSupport.on_load(:action_controller) do
        def self.reject_action_log
          cattr_accessor :_action_log_rejected
          self._action_log_rejected = true
        end
      end
    end

    initializer "wulin_audit.action_log_subscriber" do |app|
      app.config.after_initialize do
        if WulinAudit.action_log_enabled
          require "wulin_audit/action_log_subscriber"
          WulinAudit::ActionLogSubscriber.install
        end
      end
    end
  end
end
