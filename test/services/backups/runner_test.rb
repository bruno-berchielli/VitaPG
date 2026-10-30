require "test_helper"

module Backups
  class RunnerTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      @base = Dir.mktmpdir("vitapg-runner-dest-")
      @routine = backup_routines(:nightly)
      @routine.destination.update!(provider: "local", base_path: @base)
      @run = @routine.runs.create!(status: :pending, trigger: :manual)
      @runner = Runner.new(@run)
      artifact_dir = Dir.mktmpdir("vitapg-runner-artifact-")
      @artifact_path = File.join(artifact_dir, "dump.dump")
      File.binwrite(@artifact_path, "x" * 1024)
      artifact = DumpExecutor::DumpArtifact.new(path: @artifact_path, size_bytes: 1024)
      @runner.define_singleton_method(:dump!) { |_workdir| artifact }
    end

    teardown do
      FileUtils.rm_rf(@base)
      FileUtils.rm_rf(File.dirname(@artifact_path))
    end

    test "a cancel requested during the dump ends the run as canceled, without notifying" do
      runner_run = @run
      @runner.define_singleton_method(:dump!) do |_workdir|
        runner_run.request_cancel!(by: "Alice")
        raise Backups::Canceled
      end

      assert_no_enqueued_jobs(only: NotifyRunJob) { assert_not @runner.call }

      assert @run.reload.canceled?
      assert_equal "Backup canceled", @run.logs.last.message
      assert_empty Dir.glob(File.join(@base, "**", "*"))
    end

    test "a cancel requested after the dump stops before uploading" do
      runner_run = @run
      artifact = DumpExecutor::DumpArtifact.new(path: @artifact_path, size_bytes: 1024)
      @runner.define_singleton_method(:dump!) do |_workdir|
        runner_run.request_cancel!(by: "Alice")
        artifact
      end

      assert_not @runner.call
      assert @run.reload.canceled?
      assert_empty Dir.glob(File.join(@base, "**", "*.dump*"))
    end

    test "errors without a cancel request still fail the run" do
      @runner.define_singleton_method(:dump!) { |_workdir| raise Backups::Error, "pg_dump failed: boom" }

      assert_not @runner.call
      assert @run.reload.failed?
      assert_match "boom", @run.error_message
    end
  end
end
