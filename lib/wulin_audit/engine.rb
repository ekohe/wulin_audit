require "rails"

module WulinAudit
  class Engine < Rails::Engine
    engine_name :wulin_audit
    initializer "add assets to precompile" do |app|
       app.config.assets.precompile += %w( audit.css )
    end
  end
end