module WulinAudit
  module ActionLogAnalysisHelper
    SLOW_DURATION = 1_000
    VERY_SLOW_DURATION = 5_000

    # Long controller names otherwise wrap mid-word in the narrow table
    # columns; <wbr> allows a break only after "::" and "#".
    def breakable_target(target)
      safe_join(target.to_s.split(/(?<=::|#)/), tag.wbr)
    end

    def analysis_duration(milliseconds)
      return "—" if milliseconds.nil?

      tag.span(analysis_duration_text(milliseconds), class: ["duration", duration_class(milliseconds)])
    end

    # Always two decimals, so right-aligned values line up.
    def analysis_duration_text(milliseconds)
      return "—" if milliseconds.nil?

      "#{number_with_precision(milliseconds, precision: 2, delimiter: ",")} ms"
    end

    def duration_class(milliseconds)
      if milliseconds >= VERY_SLOW_DURATION
        "very-slow"
      elsif milliseconds >= SLOW_DURATION
        "slow"
      end
    end

    def status_badge(status)
      return "—" if status.nil?

      tag.span(status, class: ["status-badge", "status-#{status.to_i / 100}xx"])
    end

    def analysis_datetime(iso8601)
      iso8601.to_s.delete_suffix("Z").tr("T", " ")
    end
  end
end
