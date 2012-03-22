if defined? WulinMaster

  class AuditLogsController < WulinMaster::ScreenController
    controller_for_screen AuditLogScreen
    controller_for_grid AuditLogGrid

    add_callback :query_ready, :reset_order

    def reset_order
      @query = @query.order_by([[:created_at, :desc]])
    end
  end

end