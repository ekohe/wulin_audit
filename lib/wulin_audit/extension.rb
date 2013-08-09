module WulinAudit
  module Extension
    extend ActiveSupport::Concern

    # Inject callbacks to the orm model at include
    included do
      class_eval do
        after_create  :audit_created, :if => :auditable?
        after_update  :audit_updated, :if => :auditable?
        after_destroy :audit_deleted, :if => :auditable?
      end
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
        all_valid_column_names = (self.respond_to?(:column_names) ? self.column_names : (self.respond_to?(:fields) ? self.fields.keys : []))
        all_valid_column_names - %w(created_at updated_at)
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
        self.respond_to?(:relations)
      end
      
      def sql?
        defined? ::ActiveRecord::Base and self < ::ActiveRecord::Base
      end
    end


    def audit_created
      details = self.attributes.reject{ |k,v| audit_columns.exclude?(k) }
      details = details.inject({}){|hash, x| hash.merge(x[0] => time_convert(x[1]))}
      create_audit_log('create', details)
    end

    def audit_updated
      changes = self.changes.presence || self.previous_changes.presence
      if changes and (changes.keys & audit_columns).present?
        details = changes.reject{ |k,v| audit_columns.exclude?(k) }
        valid_details = {}
        details.each do |k,v|
          valid_details[k] = v.map{|x| time_convert(x)} 
        end
        create_audit_log('update', valid_details)
      end
    end

    def audit_deleted
      details = self.attributes.reject{ |k,v| audit_columns.exclude?(k) }
      details = details.inject({}){|hash, x| hash.merge(x[0] => time_convert(x[1]))}
      create_audit_log('delete', details)
    end

    def auditable?
      if self.class.respond_to?(:auditable)
        self.class.auditable
      else
        true
      end
    end


    protected
    
    def audit_columns
      @audit_columns ||= self.class.respond_to?(:_audit_columns) ? self.class._audit_columns : self.class.valid_column_names
    end

    def create_audit_log(action, details_content)
      details_content.merge!(parse_details(details_content))
      details_content = titleize_column_names(details_content)
      details_content.each do |k,v|
        details_content[k] = v.utc if v.kind_of?(ActiveSupport::TimeWithZone)
      end

      WulinAudit::AuditLog.create(
      :user_id => (User.current_user.try(:id) rescue nil),
      :request_ip => (User.current_user.try(:ip) rescue nil),
      :user_email => (User.current_user.try(:email) rescue nil),
      :record_id => self.id.to_s,
      :action => action,
      :class_name => self.class.name,
      :detail => details_content
      )
    rescue
      logger.fatal '----------------------------------------------------------------'
      logger.fatal "WARNING: Audit faild!  Error message: #{$!.message}"
      logger.fatal '----------------------------------------------------------------'
    end

    private
    
    # Parse details for relationed column.
    def parse_details(details)
      return details unless self.class.sql?
      
      relation_columns = details.select { |key, value| key =~ /.*_id$/ }
      relation_columns.each do |k, v|
        if relation_klass = get_relation_klass(k)
          begin
            if Array === v
              relation_columns[k] = v.map{|x| x ? relation_klass.find(x).send(human_relation_column(relation_klass)) : nil }
            else
              relation_columns[k] = v ? relation_klass.find(v).send(human_relation_column(relation_klass)) : nil
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
      details.inject({}){|hash, (k, v)| hash.merge!(k.titleize => v)}
    end
    
    def get_relation_klass(column_name)
      self.class.reflections.select{|key,value| value.foreign_key == column_name }.values.first.klass
    rescue
      nil
    end
    
    def human_relation_column(klass)
      if klass.respond_to?(:_human_relation_column)
        klass._human_relation_column
      else
        case
        when klass.column_names.include?('name')
          'name'
        when klass.column_names.include?('code')
          'code'
        else
          'id'
        end
      end
    end
    
    def time_convert(time)
      if time.is_a?(DateTime) or time.is_a?(Time)
        time.utc
      elsif time.is_a?(Date)
        time.to_s
      else
        time
      end
    end


  end
end