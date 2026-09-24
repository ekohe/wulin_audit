if defined? WulinMaster
  module WulinAudit
    class ActionLogAnalysisController < WulinMaster::ScreenController
      QUICK_RANGES = {
        "1h" => 1.hour,
        "6h" => 6.hours,
        "24h" => 24.hours,
        "7d" => 7.days,
        "30d" => 30.days,
        "6M" => 6.months
      }.freeze

      controller_for_screen ActionLogAnalysisScreen
      reject_action_log

      def index
        default_to = Time.current
        default_from = default_to - 24.hours
        @range = if QUICK_RANGES.key?(params[:range])
          params[:range]
        elsif params[:from].blank? && params[:to].blank?
          "24h"
        end
        to = parse_time(params[:to]) || default_to
        from = @range ? to - QUICK_RANGES.fetch(@range) : parse_time(params[:from]) || default_from
        from, to = [default_from, default_to] unless from < to

        @analysis = WulinAudit::ActionLogAnalysis.new(
          from: from,
          to: to,
          user: params[:user],
          target: params[:target]
        )

        super
      end

      private

      def parse_time(value)
        Time.zone.parse(value.to_s) if value.present?
      rescue ArgumentError
        nil
      end
    end
  end
end
