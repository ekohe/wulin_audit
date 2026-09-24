if defined? WulinMaster
  class ActionLogAnalysisScreen < WulinMaster::Screen
    title "Action Log Analysis"

    path "/wulin_audit/action_log_analysis"

    panel ActionLogAnalysisFilterPanel, width: "100%"
    panel ActionLogAnalysisSummaryPanel, width: "100%"
    panel ActionLogAnalysisActivityPanel, width: "50%"
    panel ActionLogAnalysisUsagePanel, width: "50%"
    panel ActionLogAnalysisPerformancePanel, width: "100%"
  end
end
