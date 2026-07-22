if defined? WulinMaster
  class ActionLogGrid < WulinMaster::Grid
    title "Action Logs"

    model WulinAudit::ActionLog

    cell_editable false

    path "/wulin_audit/action_logs"

    column :created_at, width: 150, label: "Datetime (UTC)", type: "Datetime",
      datetime_format: :with_seconds, time_zone: "UTC"
    column :request_id, width: 200
    column :user_email, width: 150, label: "User"
    column :http_method, width: 60, label: "Method"
    column :path, width: 250
    column :controller, width: 150
    column :action, width: 100
    column :status, width: 60
    column :duration, width: 80, label: "Duration (ms)"
    column :allocations, width: 100
    column :request_ip, width: 120, label: "IP"
    column :exception, width: 200
    column :params, width: 300
    column :spans, width: 400

    if defined? WulinMaster::GridActions::ORIGINAL_ACTIONS
      action :excel
      action :filter
    else
      action :export
    end
  end
end
