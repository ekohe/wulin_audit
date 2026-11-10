require "wulin_audit/extension"

class ActiveRecord::Base
  include WulinAudit::Extension
end

module WulinAudit
  module ThroughAssociation
    private

    # Rails removes has_many :through and HABTM join rows with delete_all,
    # which skips the after_destroy audit, so audit them before the delete.
    def delete_records(records, delete_method)
      if delete_method != :destroy && delete_method != :nullify
        through_association.scope.where(construct_join_attributes(*records)).where(through_scope_attributes).each do |join_record|
          join_record.send(:audit_deleted) if join_record.auditable?
        end
      end
      super
    end
  end
end

ActiveRecord::Associations::HasManyThroughAssociation.prepend WulinAudit::ThroughAssociation
