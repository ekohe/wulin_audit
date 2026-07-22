if defined? WulinMaster
  module WulinAudit
    class ActionLogsController < WulinMaster::ScreenController
      controller_for_screen ActionLogScreen
      reject_action_log
    end
  end
end
