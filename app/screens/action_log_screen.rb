if defined? WulinMaster
  class ActionLogScreen < WulinMaster::Screen
    title "Action Log"

    path "/wulin_audit/action_logs"

    grid ActionLogGrid
  end
end
