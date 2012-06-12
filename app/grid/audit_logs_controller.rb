if defined? WulinMaster

  class AuditLogsController < WulinMaster::ScreenController
    controller_for_screen AuditLogScreen

    add_callback :query_ready, :reset_order

    def reset_order
      @query = @query.order_by([[:created_at, :desc]])
    end
  end

end