module WulinAudit
  class ActionLogSubscriber
    SPAN_KEY = :wulin_audit_spans
    POOL_SIZE = 2

    def self.install
      @pool = Concurrent::FixedThreadPool.new(POOL_SIZE)
      subscribe_spans
      subscribe_transaction
      at_exit { shutdown }
    end

    def self.subscribe_spans
      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        next if event.payload[:name] == "SCHEMA" || event.payload[:cached]

        push_span("db", event.duration.round(2))
      end

      ActiveSupport::Notifications.subscribe(/render_(template|partial)\.action_view/) do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        push_span("view", event.duration.round(2))
      end
    end

    def self.subscribe_transaction
      ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload
        spans = flush_spans

        controller_class = payload[:controller]&.safe_constantize
        next if controller_class&.respond_to?(:_action_log_rejected) && controller_class._action_log_rejected

        raw_params = payload[:params]&.except(:controller, :action)

        attrs = {
          request_id: payload[:request]&.request_id,
          user_id: begin
            User.current_user.try(:id)
          rescue
            nil
          end,
          user_email: begin
            User.current_user.try(:email)
          rescue
            nil
          end,
          request_ip: payload[:request]&.remote_ip,
          http_method: payload[:method],
          path: payload[:path],
          controller: payload[:controller],
          action: payload[:action],
          params: truncate_params(filter_params(raw_params)),
          status: payload[:status],
          duration: event.duration.round(2),
          allocations: event.allocations,
          exception: payload[:exception]&.join(": "),
          spans: spans
        }

        write_async(attrs)
      end
    end

    def self.write_async(attrs)
      @pool.post do
        ActiveRecord::Base.connection_pool.with_connection do
          if ActiveRecord::Base.logger
            ActiveRecord::Base.logger.silence { WulinAudit::ActionLog.create(attrs) }
          else
            WulinAudit::ActionLog.create(attrs)
          end
        end
      rescue => e
        Rails.logger.warn "WulinAudit::ActionLog failed: #{e.message}"
      end
    end

    def self.shutdown
      @pool.shutdown
      @pool.wait_for_termination(5)
    end

    def self.push_span(type, duration)
      spans = (Thread.current[SPAN_KEY] ||= {})
      entry = (spans[type] ||= {"count" => 0, "duration" => 0.0})
      entry["count"] += 1
      entry["duration"] = (entry["duration"] + duration).round(2)
    end

    def self.flush_spans
      spans = Thread.current[SPAN_KEY] || {}
      Thread.current[SPAN_KEY] = {}
      spans
    end

    MAX_PARAMS_SIZE = 512

    def self.truncate_params(params)
      return params unless params
      json = params.to_json
      (json.bytesize > MAX_PARAMS_SIZE) ? "#{json.byteslice(0, MAX_PARAMS_SIZE).scrub}… [TRUNCATED]" : params
    end

    def self.filter_params(params)
      return params unless params
      ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(params)
    end
  end
end
