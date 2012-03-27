module WulinAudit
  module Extension
    extend ActiveSupport::Concern

    # inject callbacks to the rom model at include
    included do
      class_eval do
        after_create  :audit_created, :if => :auditable?
        after_update  :audit_updated, :if => :auditable?
        after_destroy :audit_deleted, :if => :auditable?
      end
    end
    
    module ClassMethods
      def reject_audit
        cattr_accessor :auditable
        self.auditable = false
      end
      
      def audit_columns(*columns)
        cattr_accessor :_audit_columns
        self._audit_columns = columns.map(&:to_s) & valid_column_names
      end
      
      # Get column_names for ActiveRecord and Mongoid 
      def valid_column_names
        all_valid_column_names = (self.respond_to?(:column_names) ? self.column_names : (self.respond_to?(:fields) ? self.fields.keys : []))
        all_valid_column_names - %w(created_at updated_at)
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

    # WulinAudit will audit all the models automatically; 
    # if you do not want audit some, use +reject_audit+ method:
    #   class Post < ActiveRecord::Base
    #     reject_audit
    #   end
    #
    def auditable?
      if self.class.respond_to?(:auditable)
        self.class.auditable
      else
        true
      end
    end


    protected

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
    def audit_columns
      @audit_columns ||= self.class.respond_to?(:_audit_columns) ? self.class._audit_columns : self.class.valid_column_names
    end

    def create_audit_log(action, details_content)
      details_content.each do |k,v|
        details_content[k] = v.utc if v.kind_of?(ActiveSupport::TimeWithZone)
      end

      WulinAudit::AuditLog.create(
      :user_id => User.current_user.try(:id),
      :user_email => User.current_user.try(:email),
      :record_id => self.id.to_s,
      :action => action,
      :class_name => self.class.name,
      :detail => details_content
      )
    end

    private
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