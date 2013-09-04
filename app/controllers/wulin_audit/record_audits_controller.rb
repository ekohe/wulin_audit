if defined? WulinMaster
  module WulinAudit
    class RecordAuditsController < WulinMaster::ScreenController
      controller_for_screen RecordAuditScreen

      add_callback :query_ready, :set_record_id_condition

      def set_record_id_condition
        if params[:record_ids].present? and params[:class_name].present?
          @query = @query.where(:class_name => params[:class_name].classify, :record_id.in => params[:record_ids].split(',')) 
        end
      end
    end
  end
end