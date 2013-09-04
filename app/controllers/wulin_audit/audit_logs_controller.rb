# Here are request interfaces for stand alone
# Totailly belongs to WulinAudit::AuditLog resources
# implement user interface in here,and it can be customed
if defined? WulinMaster
  module WulinAudit
    class AuditLogsController < WulinMaster::ScreenController
      controller_for_screen AuditLogScreen
    end
  end
end