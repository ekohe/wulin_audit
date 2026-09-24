require "test_helper"
require WulinAudit::Engine.root.join("db/migrate/20260910160000_create_action_log_analysis_permission").to_s

class ActionLogAnalysisPermissionTest < Minitest::Test
  def setup
    Permission.delete_all
  end

  def test_up_is_idempotent
    migration.up
    migration.up

    assert_equal 1, Permission.where(name: "action_log_analysis#read").count
  end

  def test_down_removes_permission
    migration.up

    migration.down

    refute Permission.exists?(name: "action_log_analysis#read")
  end

  private

  def migration
    @migration ||= CreateActionLogAnalysisPermission.new
  end
end
