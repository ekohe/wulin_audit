require "rails"

module WulinAudit
  class Engine < Rails::Engine
    engine_name :wulin_audit

    initializer "add assets to precompile" do |app|
       app.config.assets.precompile += %w( audit.css audit.js audit.png)
    end

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
