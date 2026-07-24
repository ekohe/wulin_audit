# Here are request interfaces for stand alone
# Totailly belongs to WulinAudit::AuditLog resources
# implement user interface in here,and it can be customed
if defined? WulinMaster
  module WulinAudit
    class AuditLogsController < WulinMaster::ScreenController
      controller_for_screen AuditLogScreen
      reject_action_log

      add_callback :query_initialized, :filter_by_request_ids

      def filter_by_request_ids
        @query = @query.where(request_id: params[:request_ids].split(",")) if params[:request_ids].present?
      end
    end
  end
end
