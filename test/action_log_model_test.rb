require "test_helper"

class ActionLogModelTest < Minitest::Test
  def setup
    WulinAudit::ActionLog.delete_all
  end

  def test_creates_with_all_attributes
    log = WulinAudit::ActionLog.create!(
      request_id: "req-1",
      user_id: 1,
      user_email: "test@example.com",
      request_ip: "127.0.0.1",
      http_method: "GET",
      path: "/posts",
      controller: "posts",
      action: "index",
      params: {"id" => "1"},
      status: 200,
      duration: 12.5,
      allocations: 100,
      exception: nil,
      spans: {"db" => {"count" => 1, "duration" => 1.0}}
    )

    log.reload
    assert_equal "req-1", log.request_id
    assert_equal 1, log.user_id
    assert_equal "test@example.com", log.user_email
    assert_equal "127.0.0.1", log.request_ip
    assert_equal "GET", log.http_method
    assert_equal "/posts", log.path
    assert_equal "posts", log.controller
    assert_equal "index", log.action
    assert_equal 200, log.status
    assert_in_delta 12.5, log.duration
    assert_equal 100, log.allocations
    assert_nil log.exception
  end

  def test_is_not_auditable
    refute WulinAudit::ActionLog.auditable
  end

  def test_params_and_spans_round_trip_as_ruby_objects
    log = WulinAudit::ActionLog.create!(
      params: {"foo" => "bar"},
      spans: {"view" => {"count" => 1, "duration" => 2.0}}
    )

    log.reload
    assert_equal({"foo" => "bar"}, log.params)
    assert_equal({"view" => {"count" => 1, "duration" => 2.0}}, log.read_attribute("spans"))
  end
end
