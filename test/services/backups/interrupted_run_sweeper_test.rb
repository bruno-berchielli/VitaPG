require "test_helper"

module Backups
  class InterruptedRunSweeperTest < ActiveSupport::TestCase
    setup do
      @routine = backup_routines(:nightly)
    end

    teardown do
      @dirs&.each { |dir| FileUtils.rm_rf(dir) }
    end

    test "fails a run that went silent and logs why" do
      run = travel_to(2.hours.ago) { @routine.runs.create!(status: :dumping, trigger: :scheduled, started_at: Time.current) }

      InterruptedRunSweeper.call

      run.reload
      assert run.failed?
      assert_not_nil run.finished_at
      assert_match "Interrupted", run.error_message
      assert_match "Interrupted", run.logs.last.message
    end

    test "leaves a run with a recent heartbeat alone" do
      run = travel_to(2.hours.ago) { @routine.runs.create!(status: :dumping, trigger: :scheduled, started_at: Time.current) }
      run.progress!(bytes: 0)

      InterruptedRunSweeper.call

      assert run.reload.dumping?
    end

    test "removes work directories of runs that are no longer in progress" do
      live = @routine.runs.create!(status: :dumping, trigger: :manual, started_at: Time.current)
      finished = @routine.runs.create!(status: :failed, trigger: :manual)
      live_dir = workdir_for(live)
      orphan_dir = workdir_for(finished)

      InterruptedRunSweeper.call

      assert Dir.exist?(live_dir)
      assert_not Dir.exist?(orphan_dir)
    end

    test "removes the partial upload of a run killed while uploading" do
      base = Dir.mktmpdir("vitapg-sweeper-dest-")
      (@dirs ||= []) << base
      @routine.destination.update!(provider: "local", base_path: base)
      run = travel_to(2.hours.ago) { @routine.runs.create!(status: :uploading, trigger: :manual, started_at: Time.current) }
      partial = File.join(base, "#{run.storage_key_stem}.dump.partial")
      other = File.join(base, "#{run.storage_key_stem.sub(/-#{run.id}\z/, "-999")}.dump.partial")
      [ partial, other ].each { |path| FileUtils.mkdir_p(File.dirname(path)) && File.write(path, "x") }

      InterruptedRunSweeper.call

      assert run.reload.failed?
      assert_not File.exist?(partial)
      assert File.exist?(other)
    end

    private

    def workdir_for(run)
      Dir.mktmpdir("vitapg-run-#{run.id}-").tap { |dir| (@dirs ||= []) << dir }
    end
  end
end
