module WulinAudit
  class ActionLogAnalysis
    MAX_RANGE = 6.months
    MAX_BUCKETS = 200
    INTERVALS = {
      "1m" => 1.minute,
      "5m" => 5.minutes,
      "15m" => 15.minutes,
      "1h" => 1.hour,
      "6h" => 6.hours,
      "1d" => 1.day
    }.freeze

    attr_reader :from, :to, :user, :target

    def initialize(from:, to:, user: nil, target: nil)
      @to = to
      @from = [from, to - MAX_RANGE].max
      @interval = automatic_interval
      @user = user.presence
      @target = target.presence
    end

    def activity_series
      counts = scope.group(Arel.sql(bucket_expression)).count.transform_keys do |bucket|
        bucket.is_a?(Time) ? bucket.to_i : Time.parse("#{bucket} UTC").to_i
      end

      first_bucket = (from.to_i / interval_seconds) * interval_seconds
      last_bucket = ((to.to_f - 0.000001).floor / interval_seconds) * interval_seconds

      (first_bucket..last_bucket).step(interval_seconds).map do |timestamp|
        {x: Time.at(timestamp).utc.iso8601, y: counts.fetch(timestamp, 0)}
      end
    end

    def by_user
      scope.where.not(user_email: [nil, ""])
        .group(:user_email)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(20)
        .count
        .map { |email, count| {label: email, count: count} }
    end

    def by_action
      scope.where.not(controller: [nil, ""])
        .select(:controller, :action, "COUNT(*) AS request_count", "AVG(duration) AS average_duration")
        .group(:controller, :action)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(20)
        .map do |row|
          {
            target: [row.controller, row.action].compact.join("#"),
            count: row.request_count,
            average_duration: row.average_duration&.to_f&.round(2)
          }
        end
    end

    def summary
      @summary ||= begin
        durations = scope.where.not(duration: nil)
        postgres? ? postgres_summary : ruby_summary(durations)
      end
    end

    def slow_by_action
      postgres? ? postgres_slow_by_action : ruby_slow_by_action
    end

    def slowest_requests
      scope.where.not(duration: nil)
        .select(:created_at, :user_email, :controller, :action, :http_method, :path, :status, :duration, :spans)
        .order(duration: :desc)
        .limit(100)
        .map do |log|
        {
          created_at: log.created_at&.utc&.iso8601,
          user: log.user_email,
          target: [log.controller, log.action].compact.join("#"),
          request: [log.http_method, log.path].compact.join(" "),
          status: log.status,
          duration: log.duration,
          db_duration: log.db_duration,
          view_duration: log.view_duration,
          action_duration: log.action_duration
        }
      end
    end

    def users
      range_scope.where.not(user_email: [nil, ""]).distinct.order(:user_email).pluck(:user_email)
    end

    def targets
      range_scope.where.not(controller: [nil, ""]).distinct.order(:controller, :action).pluck(:controller, :action).map do |controller, action|
        [controller, action].compact.join("#")
      end
    end

    private

    def range_scope
      WulinAudit::ActionLog.where("created_at >= ? AND created_at < ?", from, to)
    end

    def scope
      @scope ||= begin
        relation = range_scope
        relation = relation.where(user_email: user) if user
        if target
          controller, action = target.split("#", 2)
          relation = relation.where(controller: controller, action: action)
        end
        relation
      end
    end

    def automatic_interval
      seconds = to.to_i - from.to_i
      INTERVALS.find { |_name, value| seconds / value <= MAX_BUCKETS }&.first || "1d"
    end

    def interval_seconds
      INTERVALS.fetch(@interval).to_i
    end

    def bucket_expression
      if postgres?
        "TO_TIMESTAMP(FLOOR(EXTRACT(EPOCH FROM created_at) / #{interval_seconds}) * #{interval_seconds})"
      else
        "DATETIME((CAST(STRFTIME('%s', created_at) AS INTEGER) / #{interval_seconds}) * #{interval_seconds}, 'unixepoch')"
      end
    end

    def postgres_summary
      row = scope.select(
        "COUNT(*) AS total_count",
        "AVG(duration) AS average_duration",
        "PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration) AS p95_duration"
      ).take
      {
        total: row.total_count,
        average_duration: row.average_duration&.to_f&.round(2),
        p95_duration: row.p95_duration&.to_f&.round(2)
      }
    end

    def ruby_summary(durations)
      values = durations.pluck(:duration)
      {
        total: scope.count,
        average_duration: values.any? ? (values.sum / values.length).round(2) : nil,
        p95_duration: ruby_percentile(values)
      }
    end

    def postgres_slow_by_action
      scope.where.not(duration: nil)
        .select(
          :controller,
          :action,
          "COUNT(*) AS request_count",
          "AVG(duration) AS average_duration",
          "MAX(duration) AS maximum_duration",
          "PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration) AS p95_duration"
        )
        .group(:controller, :action)
        .order(Arel.sql("p95_duration DESC"))
        .limit(20)
        .map do |row|
          {
            target: [row.controller, row.action].compact.join("#"),
            count: row.request_count,
            average_duration: row.average_duration.to_f.round(2),
            p95_duration: row.p95_duration.to_f.round(2),
            maximum_duration: row.maximum_duration.to_f.round(2)
          }
        end
    end

    def ruby_slow_by_action
      scope.where.not(duration: nil).pluck(:controller, :action, :duration)
        .group_by { |controller, action, _duration| [controller, action] }
        .map do |(controller, action), rows|
          durations = rows.map(&:last)
          {
            target: [controller, action].compact.join("#"),
            count: durations.length,
            average_duration: (durations.sum / durations.length).round(2),
            p95_duration: ruby_percentile(durations),
            maximum_duration: durations.max.round(2)
          }
        end
        .sort_by { |row| -row[:p95_duration] }
        .first(20)
    end

    def ruby_percentile(values)
      return if values.empty?

      sorted = values.sort
      sorted[((sorted.length - 1) * 0.95).round].round(2)
    end

    def postgres?
      WulinAudit::ActionLog.connection.adapter_name == "PostgreSQL"
    end
  end
end
