require "test_helper"
require "action_view"
require WulinAudit::Engine.root.join("app/helpers/wulin_audit/action_log_analysis_helper").to_s

class ActionLogAnalysisHelperTest < Minitest::Test
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::NumberHelper
  include WulinAudit::ActionLogAnalysisHelper

  def test_breakable_target_breaks_only_after_namespace_and_action_separator
    assert_equal "WulinMaster::<wbr>UserPreferencesController#<wbr>show",
      breakable_target("WulinMaster::UserPreferencesController#show")
  end

  def test_duration_marks_slow_and_very_slow
    assert_equal %(<span class="duration">999.50 ms</span>), analysis_duration(999.5)
    assert_equal %(<span class="duration slow">1,000.00 ms</span>), analysis_duration(1000)
    assert_equal %(<span class="duration very-slow">28,194.55 ms</span>), analysis_duration(28194.55)
    assert_equal "—", analysis_duration(nil)
  end

  def test_status_badge_class_follows_status_family
    assert_equal %(<span class="status-badge status-2xx">200</span>), status_badge(200)
    assert_equal %(<span class="status-badge status-3xx">302</span>), status_badge(302)
    assert_equal %(<span class="status-badge status-4xx">404</span>), status_badge(404)
    assert_equal %(<span class="status-badge status-5xx">500</span>), status_badge(500)
    assert_equal "—", status_badge(nil)
  end

  def test_datetime_drops_iso_separators
    assert_equal "2026-09-15 07:03:48", analysis_datetime("2026-09-15T07:03:48Z")
  end
end
