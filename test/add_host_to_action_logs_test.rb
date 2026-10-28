require "test_helper"

class AddHostToActionLogsTest < Minitest::Test
  def test_adds_host_column_and_index
    connection = WulinAudit::ActionLog.connection

    assert connection.column_exists?(:action_logs, :host, :string)
    assert connection.index_exists?(:action_logs, [:host, :created_at])
  end

  # The test helper already ran it once, as the first app on a shared database would.
  def test_second_run_is_a_no_op
    ActiveRecord::Migration.suppress_messages { AddHostToActionLogs.migrate(:up) }

    assert WulinAudit::ActionLog.connection.column_exists?(:action_logs, :host, :string)
  end
end
