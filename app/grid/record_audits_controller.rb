if defined? WulinMaster
  class RecordAuditsController < WulinMaster::ScreenController
    controller_for_screen RecordAuditScreen

    add_callback :query_ready, :set_record_id_condition
    add_callback :query_ready, :reset_order

    protected

    def reset_order
      @query = @query.order_by([[:created_at, :desc]])
    end

    def set_record_id_condition
      if params[:record_ids].present? and params[:class_name].present?
        @query = @query.where(:class_name => params[:class_name].classify, :record_id.in => params[:record_ids].split(',')) 
      end
    end
  end
end