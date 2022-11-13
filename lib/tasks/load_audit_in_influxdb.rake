namespace :wulin_audit do
  desc 'Load audit log into InfluxDB'
  task load_audit_in_influxdb: :environment do
    require 'ruby-progressbar'

    bar = ProgressBar.create(format: '%t %a %e %P% %B Processed: %c from %C', starting_at: 0, total: WulinAudit::AuditLog.count)

    def line_escape(string)
      return string unless string.is_a?(String)
      string.gsub(" ", "\ ").gsub("=", "\=").gsub(",", "\,")
    end

    WulinAudit::AuditLog.find_each do |log|
      bar.increment
      attributes = log.attributes.with_indifferent_access
      http = Net::HTTP.new(APP_CONFIG["wulin_audit"]["influxdb"]["host"], APP_CONFIG["wulin_audit"]["influxdb"]["port"])
      url = "/write?consistency=all&db=#{APP_CONFIG["wulin_audit"]["influxdb"]["database"]}&precision=s&rp="

      # Tags
      influx_tags = attributes.except(:detail, :record_id, :created_at, :updated_at)
      tags = influx_tags.keys.map{|k| influx_tags[k].nil? ? nil : "#{k}=#{line_escape(influx_tags[k])}" }.compact.join(",")

      # Fields
      influx_fields = {"record_id" => attributes[:record_id].to_i, "value" => 1}
      fields = influx_fields.keys.map{|k| influx_fields[k].nil? ? nil : "#{k}=#{line_escape(influx_fields[k].is_a?(String) ? influx_fields[k].inspect : influx_fields[k])}" }.compact.join(",")

      tags = "," + tags if tags.size > 0
      line = "activity#{tags} #{fields} #{log.created_at.utc.to_i}"
      request = Net::HTTP::Post.new(url, { "Content-Type" => "application/octet-stream" })
      request.body = line
      response = http.request(request)
      if response.code != '204'
        puts "Write to InfluxDB failed:"
        puts line
        puts response.body
      end
    end
  end
end
