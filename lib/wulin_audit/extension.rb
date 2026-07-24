module WulinAudit
  module Extension
    extend ActiveSupport::Concern

    # Inject callbacks to the orm model at include
    included do
      after_create :audit_created, if: :auditable?
      after_update :audit_updated, if: :auditable?
      after_destroy :audit_deleted, if: :auditable?
    end

    module ClassMethods
      # WulinAudit will audit all the models automatically;
      # if you do not want audit some, use +reject_audit+ method:
      #   class Post < ActiveRecord::Base
      #     reject_audit
      #   end
      #
      def reject_audit
        cattr_accessor :auditable
        self.auditable = false
      end

      # If a module was audited, WulinAudit will audit all the columns automatically,
      # You also can control which columns need audit, you need use +audit_columns+ method:
      #
      #   class Post < ActiveRecord::Base
      #     audit_columns(%w(title content category) & column_names)
      #     audit_columns :title, :content, :category
      #     audit_columns 'title', 'content', 'category'
      #   end
      #
      # Note that, +audit_columns+ will be ignored when audit be rejected by +reject_audit+ method.
      def audit_columns(*columns)
        cattr_accessor :_audit_columns
        self._audit_columns = columns.map(&:to_s) & valid_column_names
      end

      # Get column_names for ActiveRecord and Mongoid
      def valid_column_names
        all_valid_column_names = (if respond_to?(:column_names)
                                    column_names
                                  else
                                    (respond_to?(:fields) ? fields.keys : [])
        end)
        all_valid_column_names - %w[created_at updated_at]
      end

      # Override this method in model to set relation column to the exactly column
      # Default is +name+, and then +code+, and then is +id+
      #
      #   class Post < ActiveRecord::Base
      #     human_relation_column :title
      #   end
      #
      def human_relation_column(column_name)
        cattr_accessor :_human_relation_column
        self._human_relation_column = column_name.to_s
      end

      def nosql?
        respond_to?(:relations)
      end

      def sql?
        defined? ::ActiveRecord::Base and self < ::ActiveRecord::Base
      end
    end

    def audit_created
      details = attributes.reject { |k, v| audit_columns.exclude?(k) }
      details = details.inject({}) { |hash, x| hash.merge(x[0] => time_convert(x[1])) }
      create_audit_log("create", details)
    end

    def audit_updated
      changes = if Rails::VERSION::MAJOR >= 4
        saved_changes.presence || previous_changes.presence
      else
        self.changes.presence || previous_changes.presence
      end
      if changes && (changes.keys & audit_columns).present?
        details = changes.reject { |k, v| audit_columns.exclude?(k) }
        valid_details = {}
        details.each do |k, v|
          valid_details[k] = v.map { |x| time_convert(x) }
        end
        create_audit_log("update", valid_details)
      end
    end

    def audit_deleted
      details = attributes.reject { |k, v| audit_columns.exclude?(k) }
      details = details.inject({}) { |hash, x| hash.merge(x[0] => time_convert(x[1])) }
      create_audit_log("delete", details)
    end

    def auditable?
      if self.class.respond_to?(:auditable)
        self.class.auditable
      else
        !instance_of?(::ActiveRecord::SchemaMigration)
      end
    end

    protected

    def audit_columns
      @audit_columns ||= self.class.respond_to?(:_audit_columns) ? self.class._audit_columns : self.class.valid_column_names
    end

    def create_audit_log(action, details_content)
      details_content.merge!(parse_details(details_content))
      details_content = titleize_column_names(details_content)
      details_content.each do |k, v|
        details_content[k] = v.utc if v.is_a?(ActiveSupport::TimeWithZone)
      end

      if Rails::VERSION::MAJOR <= 4
        details_content = details_content.to_json
      end

      attributes = {user_id: begin
        User.current_user.try(:id)
      rescue
        nil
      end,
                    request_id: Thread.current[:wulin_audit_request_id],
                    request_ip: begin
                      User.current_user.try(:ip)
                    rescue
                      nil
                    end,
                    user_email: begin
                      User.current_user.try(:email)
                    rescue
                      nil
                    end,
                    record_id: id.to_s,
                    action: action,
                    class_name: self.class.name,
                    detail: details_content}

      WulinAudit::AuditLog.create(attributes)

      if APP_CONFIG["wulin_audit"] && APP_CONFIG["wulin_audit"]["influxdb"]
        http = Net::HTTP.new(APP_CONFIG["wulin_audit"]["influxdb"]["host"], APP_CONFIG["wulin_audit"]["influxdb"]["port"])
        url = "/write?consistency=all&db=#{APP_CONFIG["wulin_audit"]["influxdb"]["database"]}&precision=s&rp="

        # Tags
        influx_tags = attributes.except(:detail, :record_id)
        tags = influx_tags.keys.map { |k| influx_tags[k].nil? ? nil : "#{k}=#{line_escape(influx_tags[k])}" }.compact.join(",")

        # Fields
        influx_fields = {"record_id" => attributes[:record_id].to_i, "value" => 1}
        fields = influx_fields.keys.map { |k|
          if influx_fields[k].nil?
            nil
          else
            "#{k}=#{line_escape(influx_fields[k].is_a?(String) ? influx_fields[k].inspect : influx_fields[k])}"
          end
        }.compact.join(",")

        tags = "," + tags if tags.size > 0
        line = "activity#{tags} #{fields}"
        request = Net::HTTP::Post.new(url, {"Content-Type" => "application/octet-stream"})
        request.body = line
        response = http.request(request)
        if response.code != "204"
          Rails.logger.warn "Write to InfluxDB failed:"
          Rails.logger.warn line
          Rails.logger.warn response.body
        end
      end
    rescue
      logger.fatal "----------------------------------------------------------------"
      logger.fatal "WARNING: Audit failed!  Error message: #{$!.message}"
      logger.fatal "----------------------------------------------------------------"
    end

    def class_name_for_audit
      self.class.respond_to?(:audit_class_name) ? self.class.audit_class_name : self.class.name
    end

    private

    def line_escape(string)
      return string unless string.is_a?(String)
      string.tr(" ", " ").tr("=", "=").tr(",", ",")
    end

    # Parse details for relationed column.
    def parse_details(details)
      return details unless self.class.sql?

      relation_columns = details.select { |key, value| key =~ /.*_id$/ }
      relation_columns.each do |k, v|
        if (relation_klass = get_relation_klass(k))
          begin
            relation_columns[k] = if Array === v
              v.map { |x| x ? relation_klass.find(x).send(human_relation_column(relation_klass)) : nil }
            else
              v ? relation_klass.find(v).send(human_relation_column(relation_klass)) : nil
            end
          # rescue ActiveRecord::RecordNotFound
          rescue # Handle all error
            relation_columns[k] = v
          end
        end
      end
      relation_columns
    end

    def titleize_column_names(details)
      details.inject({}) { |hash, (k, v)| hash.merge!(k.titleize => v) }
    end

    def get_relation_klass(column_name)
      reflection = self.class.reflections.find do |key, value|
        value.foreign_key.to_s == column_name.to_s
      rescue
        nil
      end&.last

      return nil unless reflection

      if reflection.polymorphic?
        # For polymorphic associations, get the class from the type column
        type_column = reflection.foreign_type
        type_value = send(type_column)
        type_value&.constantize
      else
        reflection.klass
      end
    end

    def human_relation_column(klass)
      if klass.respond_to?(:_human_relation_column)
        klass._human_relation_column
      elsif klass.column_names.include?("name")
        "name"
      elsif klass.column_names.include?("code")
        "code"
      else
        "id"
      end
    end

    def time_convert(time)
      if time.is_a?(DateTime) || time.is_a?(Time)
        time.utc
      elsif time.is_a?(Date)
        time.to_s
      else
        time
      end
    end
  end
end
