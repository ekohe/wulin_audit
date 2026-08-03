require "test_helper"

class ActionLogSubscriberTest < Minitest::Test
  def setup
    WulinAudit::ActionLog.delete_all
    # delete_all above fires its own sql.active_record notification; flush it
    # so each test starts with a clean span buffer.
    WulinAudit::ActionLogSubscriber.flush_spans
    WulinAudit::ActionLogSubscriber.install
  end

  def test_push_span_and_flush_spans
    WulinAudit::ActionLogSubscriber.push_span("db", 1.0)
    WulinAudit::ActionLogSubscriber.push_span("db", 2.0)
    WulinAudit::ActionLogSubscriber.push_span("view", 3.0)

    spans = WulinAudit::ActionLogSubscriber.flush_spans
    assert_equal 2, spans.size
    assert_equal({"count" => 2, "duration" => 3.0}, spans["db"])
    assert_equal({"count" => 1, "duration" => 3.0}, spans["view"])

    # flushing clears the thread-local buffer
    assert_equal({}, WulinAudit::ActionLogSubscriber.flush_spans)
  end

  def test_sql_notification_pushes_db_span
    WulinAudit::ActionLogSubscriber.flush_spans

    ActiveSupport::Notifications.instrument("sql.active_record", name: "Post Load", sql: "SELECT * FROM posts") {}

    spans = WulinAudit::ActionLogSubscriber.flush_spans
    assert_equal 1, spans.size
    assert_equal({"count" => 1}, spans["db"].slice("count"))
  end

  def test_sql_notification_skips_schema_and_cached_queries
    WulinAudit::ActionLogSubscriber.flush_spans

    ActiveSupport::Notifications.instrument("sql.active_record", name: "SCHEMA", sql: "PRAGMA table_info") {}
    ActiveSupport::Notifications.instrument("sql.active_record", name: "Post Load", sql: "SELECT 1", cached: true) {}

    assert_equal({}, WulinAudit::ActionLogSubscriber.flush_spans)
  end

  def test_render_notification_pushes_view_span
    WulinAudit::ActionLogSubscriber.flush_spans

    ActiveSupport::Notifications.instrument("render_template.action_view", identifier: "/app/views/posts/index.html.erb") {}

    spans = WulinAudit::ActionLogSubscriber.flush_spans
    assert_equal({"count" => 1}, spans["view"].slice("count"))
  end

  def test_process_action_notification_writes_action_log
    WulinAudit::ActionLogSubscriber.flush_spans
    WulinAudit::ActionLogSubscriber.push_span("db", 1.0)
    WulinAudit::ActionLogSubscriber.push_span("view", 2.5)

    mock_request = Struct.new(:request_id, :remote_ip).new("req-123", "10.0.0.1")

    ActiveSupport::Notifications.instrument(
      "process_action.action_controller",
      request: mock_request,
      method: "GET",
      path: "/posts",
      controller: "posts",
      action: "index",
      params: {"controller" => "posts", "action" => "index", "id" => "1"}.with_indifferent_access,
      status: 200
    ) {}

    log = WulinAudit::ActionLog.last
    refute_nil log
    assert_equal "req-123", log.request_id
    assert_equal "10.0.0.1", log.request_ip
    assert_equal "GET", log.http_method
    assert_equal "/posts", log.path
    assert_equal "posts", log.controller
    assert_equal "index", log.action
    assert_equal({"id" => "1"}, log.params)
    assert_equal 200, log.status
    assert_equal 1, log.user_id
    assert_equal "test@example.com", log.user_email
    spans = log.read_attribute("spans")
    assert_equal({"count" => 1, "duration" => 1.0}, spans["db"])
    assert_equal({"count" => 1, "duration" => 2.5}, spans["view"])
  end

  def test_write_swallows_errors_so_requests_are_never_broken
    WulinAudit::ActionLogSubscriber.write(no_such_column: "boom")

    assert_equal 0, WulinAudit::ActionLog.count
  end

  # The test above raises in Ruby, before any SQL is sent. This one is rejected
  # by the database itself — the only path that can abort a transaction.
  def test_write_swallows_database_errors_and_leaves_the_transaction_usable
    WulinAudit::ActionLog.create!(id: 1, request_id: "taken")

    WulinAudit::ActionLog.transaction do
      WulinAudit::ActionLogSubscriber.write(id: 1, request_id: "duplicate")

      assert_equal 1, WulinAudit::ActionLog.count
      WulinAudit::ActionLog.create!(request_id: "after-failure")
    end

    assert_equal 2, WulinAudit::ActionLog.count
  end

  # The INSERT has to run one transaction level below its caller's. On
  # PostgreSQL that savepoint is the only thing keeping a rejected INSERT from
  # aborting the caller's transaction and killing every statement after it with
  # PG::InFailedSqlTransaction. SQLite has no aborted-transaction state, so
  # assert on the nesting rather than the symptom.
  def test_write_isolates_its_insert_one_transaction_level_down
    depth_at_insert = nil
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      payload = ActiveSupport::Notifications::Event.new(*args).payload
      next unless payload[:name] == "WulinAudit::ActionLog Create"
      depth_at_insert ||= ActiveRecord::Base.connection_pool.lease_connection.open_transactions
    end

    WulinAudit::ActionLog.transaction do
      assert_equal 1, ActiveRecord::Base.connection_pool.lease_connection.open_transactions
      WulinAudit::ActionLogSubscriber.write(request_id: "nested-1")
    end

    assert_equal 2, depth_at_insert
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def test_notification_writes_the_row
    ActiveSupport::Notifications.instrument(
      "process_action.action_controller",
      request: Struct.new(:request_id, :remote_ip).new("e2e-1", "10.0.0.4"),
      method: "GET", path: "/posts", controller: "posts", action: "index",
      params: {}, status: 200
    ) {}

    refute_nil WulinAudit::ActionLog.find_by(request_id: "e2e-1")
  end

  def test_write_does_not_bill_its_own_insert_to_the_next_request
    ActiveSupport::Notifications.instrument(
      "process_action.action_controller",
      request: Struct.new(:request_id, :remote_ip).new("span-leak-1", "10.0.0.5"),
      method: "GET", path: "/posts", controller: "posts", action: "index",
      params: {}, status: 200
    ) {}

    assert_equal({}, WulinAudit::ActionLogSubscriber.flush_spans)
  end

  def test_install_is_idempotent_so_notifications_are_not_double_subscribed
    WulinAudit::ActionLog.delete_all
    WulinAudit::ActionLogSubscriber.install
    WulinAudit::ActionLogSubscriber.install

    ActiveSupport::Notifications.instrument(
      "process_action.action_controller",
      request: Struct.new(:request_id, :remote_ip).new("once-1", "10.0.0.3"),
      method: "GET", path: "/posts", controller: "posts", action: "index",
      params: {}, status: 200
    ) {}

    assert_equal 1, WulinAudit::ActionLog.where(request_id: "once-1").count
  end

  def test_filter_params_applies_rails_filter_parameters
    stub_filter_parameters([:password]) do
      filtered = WulinAudit::ActionLogSubscriber.filter_params("user" => "mel", "password" => "secret")
      assert_equal "mel", filtered["user"]
      assert_equal "[FILTERED]", filtered["password"]
    end
  end

  def test_truncate_params_returns_hash_when_within_limit
    result = WulinAudit::ActionLogSubscriber.truncate_params("id" => "1")
    assert_kind_of Hash, result
    assert_equal "1", result["id"]
  end

  def test_truncate_params_returns_truncated_string_when_over_limit
    big = {"file" => "x" * 1000}
    result = WulinAudit::ActionLogSubscriber.truncate_params(big)
    assert_kind_of String, result
    assert result.end_with?("… [TRUNCATED]")
    assert_operator result.bytesize, :<=, 512 + "… [TRUNCATED]".bytesize
  end

  def test_truncate_params_produces_valid_encoding_when_cut_lands_mid_character
    big = {"note" => "中" * 300}
    result = WulinAudit::ActionLogSubscriber.truncate_params(big)
    assert_kind_of String, result
    assert result.valid_encoding?
    assert result.end_with?("… [TRUNCATED]")
  end

  def test_end_to_end_sql_view_and_controller_notifications
    WulinAudit::ActionLog.delete_all
    WulinAudit::ActionLogSubscriber.flush_spans

    mock_request = Struct.new(:request_id, :remote_ip).new("req-e2e", "10.0.0.2")

    ActiveSupport::Notifications.instrument("sql.active_record", name: "Post Load", sql: "SELECT * FROM posts") {}
    ActiveSupport::Notifications.instrument("render_template.action_view", identifier: "/app/views/posts/index.html.erb") {}
    ActiveSupport::Notifications.instrument(
      "process_action.action_controller",
      request: mock_request,
      method: "GET",
      path: "/posts",
      controller: "posts",
      action: "index",
      params: {"controller" => "posts", "action" => "index"},
      status: 200
    ) {}

    assert_equal 1, WulinAudit::ActionLog.count
    log = WulinAudit::ActionLog.find_by(request_id: "req-e2e")
    refute_nil log
    spans = log.read_attribute("spans")
    assert_equal 2, spans.size
    assert_equal 1, spans["db"]["count"]
    assert_equal 1, spans["view"]["count"]
  end

  private

  def stub_filter_parameters(filters)
    app = Struct.new(:config).new(Struct.new(:filter_parameters).new(filters))
    original_app = Rails.application
    Rails.instance_variable_set(:@application, app)
    yield
  ensure
    Rails.instance_variable_set(:@application, original_app)
  end
end
