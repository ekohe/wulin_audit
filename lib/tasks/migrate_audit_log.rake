namespace :wulin_audit do
  desc 'Migrate audit_log from MongoDB to PostgreSQL'
  task migrate_audit_log: :environment do
    require 'mongo'

    host = ENV['host'] || '127.0.0.1'
    url = "#{host}:27017"
    mongodb = ENV['mongodb'] || 'bss_development'

    Mongo::Logger.logger.level = ::Logger::FATAL

    begin
      client = Mongo::Client.new([url], database: mongodb, server_selection_timeout: 3)
      client[:wulin_audit_audit_logs].find.each do |mongo_log|
        WulinAudit::AuditLog.create(
          user_id: mongo_log[:user_id],
          request_ip: mongo_log[:request_ip],
          user_email: mongo_log[:user_email],
          record_id: mongo_log[:record_id],
          action: mongo_log[:action],
          class_name: mongo_log[:class_name],
          detail: mongo_log[:detail],
          created_at: mongo_log[:created_at]
        )
        print '.'
      end
      client.close
      puts ''
      puts "#{client[:wulin_audit_audit_logs].count()} audit logs converted"
    rescue Mongo::Error => e
      puts e
    end
  end
end
