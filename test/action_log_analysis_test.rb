require "test_helper"

class ActionLogAnalysisTest < Minitest::Test
  FROM = Time.utc(2026, 9, 10, 10)
  TO = Time.utc(2026, 9, 10, 11)

  def setup
    WulinAudit::ActionLog.delete_all
  end

  def test_zero_fills_activity_buckets
    create_log(created_at: FROM + 5.minutes)
    create_log(created_at: FROM + 35.minutes)

    result = WulinAudit::ActionLogAnalysis.new(from: FROM, to: FROM + 1.day)
    series = result.activity_series

    assert_equal [1, 0, 1], series.first(3).map { |point| point[:y] }
    assert_equal 96, series.length
  end

  def test_filters_by_user_and_controller_action
    create_log(user_email: "one@example.com", controller: "PeopleController", action: "index")
    create_log(user_email: "two@example.com", controller: "PeopleController", action: "show")

    result = analysis(user: "one@example.com", target: "PeopleController#index")

    assert_equal 1, result.summary[:total]
    assert_equal [{label: "one@example.com", count: 1}], result.by_user
    assert_equal(
      [{target: "PeopleController#index", count: 1, average_duration: 10.0}],
      result.by_action
    )
  end

  def test_summary_calculates_average_and_p95
    [10, 20, 30, 40, 100].each { |duration| create_log(duration: duration) }

    summary = analysis.summary

    assert_equal 5, summary[:total]
    assert_in_delta 40, summary[:average_duration]
    assert_in_delta 100, summary[:p95_duration]
  end

  def test_slow_action_summary_is_ordered_by_p95
    create_log(controller: "FastController", duration: 10)
    create_log(controller: "SlowController", duration: 200)

    rows = analysis.slow_by_action

    assert_equal ["SlowController#index", "FastController#index"], rows.map { |row| row[:target] }
    assert_equal 200, rows.first[:maximum_duration]
  end

  def test_slowest_requests_are_limited_to_100
    105.times { |index| create_log(duration: index) }

    rows = analysis.slowest_requests

    assert_equal 100, rows.length
    assert_equal 104, rows.first[:duration]
    assert_equal 5, rows.last[:duration]
  end

  def test_slowest_requests_separate_path_from_query_string
    create_log(path: "/people?filter=active&page=2")

    row = analysis.slowest_requests.first

    assert_equal "/people", row[:path]
    assert_equal "/people?filter=active&page=2", row[:full_path]
  end

  def test_filter_options_ignore_selected_filters
    create_log(user_email: "one@example.com", controller: "PeopleController", action: "index")
    create_log(user_email: "two@example.com", controller: "TeamsController", action: "show")

    result = analysis(user: "one@example.com")

    assert_equal ["one@example.com", "two@example.com"], result.users
    assert_equal ["PeopleController#index", "TeamsController#show"], result.targets
  end

  def test_auto_interval_keeps_bucket_count_bounded
    result = WulinAudit::ActionLogAnalysis.new(from: FROM, to: FROM + 30.days)

    assert_operator result.activity_series.length, :<=, 200
  end

  def test_range_is_limited_to_six_months
    result = WulinAudit::ActionLogAnalysis.new(from: FROM - 1.year, to: FROM)

    assert_equal FROM - 6.months, result.from
  end

  private

  def analysis(options = {})
    WulinAudit::ActionLogAnalysis.new(from: FROM, to: TO, **options)
  end

  def create_log(attributes = {})
    WulinAudit::ActionLog.create!(
      {
        request_id: SecureRandom.uuid,
        user_email: "one@example.com",
        http_method: "GET",
        path: "/people",
        controller: "PeopleController",
        action: "index",
        status: 200,
        duration: 10,
        created_at: FROM + 1.minute
      }.merge(attributes)
    )
  end
end
