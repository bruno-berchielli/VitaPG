require "test_helper"

module Backups
  class MissedRunCheckerTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      # Fixture cron: daily at 03:00 UTC.
      @routine = backup_routines(:nightly)
      @after_grace = Time.utc(2026, 8, 29, 4, 0)
    end

    test "alerts when the scheduled run never happened" do
      assert MissedRunChecker.call(@routine, now: @after_grace)
      assert_not_nil @routine.reload.last_missed_alert_at
    end

    test "enqueues notifications to failure channels" do
      assert_enqueued_jobs 2, only: NotifyMissedRunJob do
        MissedRunChecker.call(@routine, now: @after_grace)
      end
    end

    test "quiet when a run exists after the expected time" do
      @routine.runs.create!(status: :completed, created_at: Time.utc(2026, 8, 29, 3, 1),
                            started_at: Time.utc(2026, 8, 29, 3, 1), finished_at: Time.utc(2026, 8, 29, 3, 2))

      assert_not MissedRunChecker.call(@routine, now: @after_grace)
    end

    test "quiet inside the grace window" do
      assert_not MissedRunChecker.call(@routine, now: Time.utc(2026, 8, 29, 3, 10))
    end

    test "does not alert twice for the same occurrence" do
      assert MissedRunChecker.call(@routine, now: @after_grace)
      assert_not MissedRunChecker.call(@routine.reload, now: @after_grace + 1.hour)
    end

    test "quiet for disabled routines" do
      @routine.update!(enabled: false)

      assert_not MissedRunChecker.call(@routine, now: @after_grace)
    end
  end
end
