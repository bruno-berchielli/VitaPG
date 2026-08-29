require "test_helper"

module Backups
  class AnomalyCheckerTest < ActiveSupport::TestCase
    setup do
      @routine = backup_routines(:nightly)
    end

    def create_run(size, status: :completed)
      @routine.runs.create!(status: status, size_bytes: size, file_key: "a/#{SecureRandom.hex(4)}.dump",
                            started_at: 1.minute.ago, finished_at: Time.current)
    end

    test "flags a run far from the recent average" do
      3.times { create_run(1000) }
      run = create_run(100)

      assert AnomalyChecker.call(run)
      assert run.logs.warning.exists?
    end

    test "stays quiet within normal variation" do
      3.times { create_run(1000) }
      run = create_run(1100)

      assert_not AnomalyChecker.call(run)
    end

    test "needs history before judging" do
      create_run(1000)
      run = create_run(100)

      assert_not AnomalyChecker.call(run)
    end
  end
end
