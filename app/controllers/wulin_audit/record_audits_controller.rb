if defined? WulinMaster
  module WulinAudit
    class RecordAuditsController < WulinMaster::ScreenController
      controller_for_screen RecordAuditScreen

      add_callback :query_ready, :set_record_id_condition

      def set_record_id_condition
        if params[:record_ids].present? and params[:class_name].present?
          @query = @query.where(:class_name => class_name_for_query, :record_id => params[:record_ids].split(','))
        end
      end

      def class_name_for_query
        klass_name = params[:class_name].classify
        klass = klass_name.safe_constantize

        if klass && klass.respond_to?(:audit_class_name)
          klass.audit_class_name
        else
          klass_name
        end
      end
    end
  end
end
