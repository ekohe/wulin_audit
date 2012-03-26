module WulinAudit
  module Extension
    extend ActiveSupport::Concern

    # inject callbacks to the rom model at include
    included do
      class_eval do
        after_create :audit_created,  :if => :audit?
        after_update :audit_updated,  :if => :audit?
        after_destroy :audit_deleted, :if => :audit?
      end
    end


    def audit_created
      details = self.attributes.reject{ |k,v| !audit_columns.include?(k) }
      details = details.inject({}){|hash, x| hash.merge(x[0] => time_convert(x[1]))}
      create_audit_log('create', details)
    end

    def audit_updated
      changes = self.changes.presence || self.previous_changes.presence
      if changes and (changes.keys & audit_columns).present?
        details = changes.reject{ |k,v| !audit_columns.include?(k) }
        valid_details = {}
        details.each do |k,v|
          valid_details[k] = v.map{|x| time_convert(x)} 
        end
        create_audit_log('update', valid_details)
      end
    end

    def audit_deleted
      details = self.attributes.reject{ |k,v| !audit_columns.include?(k) }
      details = details.inject({}){|hash, x| hash.merge(x[0] => time_convert(x[1]))}
      create_audit_log('delete', details)
    end

    # WulinAudit will audit all the models; if you do not want audit some, 
    # please define +REJECT_AUDIT+ const and assign to 'true', like:
    #
    #   class Post < ActiveRecord::Base
    #     REJECT_AUDIT = true
    #   end
    #
    def audit?
      !self.class.const_defined?('REJECT_AUDIT') or (self.class.const_defined?('REJECT_AUDIT') and !self.class::REJECT_AUDIT)
    end


    protected

    # If a module was audited, WulinAudit will audit all the columns, 
    # You also can control which columns need audit, you need define +AUDIT_COLUMNS+ const
    # 
    #   class Post < ActiveRecord::Base
    #     AUDIT_COLUMNS = %w(title content category) & column_names
    #   end
    #
    def audit_columns
      klass = self.class
      @audit_columns ||= klass.const_defined?("AUDIT_COLUMNS") ? klass::AUDIT_COLUMNS : 
      (klass.respond_to?(:column_names) ? klass.column_names : (klass.respond_to?(:fields) ? klass.fields.keys : [])) - %w(created_at updated_at)
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