require "test_helper"

module Backups
  class DumpExecutorTest < ActiveSupport::TestCase
    setup do
      @run = backup_routines(:nightly).runs.create!(status: :dumping, trigger: :manual)
      @executor = DumpExecutor.new(@run, workdir: Dir.tmpdir)
    end

    test "logs a history line when pg_dump moves to a new table" do
      @executor.send(:handle_stderr_line, 'pg_dump: dumping contents of table "public.users"')

      assert_equal 1, table_log_lines.count
      assert_equal 'Dumping table "public.users"', @run.logs.last.message
    end

    test "repeated and rapid table lines do not flood the log" do
      @executor.send(:handle_stderr_line, 'pg_dump: dumping contents of table "public.users"')
      @executor.send(:handle_stderr_line, 'pg_dump: dumping contents of table "public.users"')
      @executor.send(:handle_stderr_line, 'pg_dump: dumping contents of table "public.tiny"')

      assert_equal 1, table_log_lines.count
    end

    test "non-table verbose lines only feed the live detail" do
      @executor.send(:handle_stderr_line, "pg_dump: reading indexes")

      assert_equal 0, @run.logs.count
      assert_equal "reading indexes", @executor.instance_variable_get(:@latest_line)
    end

    test "refuses to start when free space cannot hold the last dump plus the reserve" do
      completed_run(size_bytes: 10.gigabytes)
      free_disk(10.5.gigabytes)

      error = assert_raises(Backups::Error) { @executor.send(:ensure_disk_space!) }
      assert_match "Not enough disk space", error.message
      assert_match "10 GB for the dump", error.message
    end

    test "starts when free space holds the last dump plus the reserve" do
      completed_run(size_bytes: 10.gigabytes)
      free_disk(20.gigabytes)

      assert_nothing_raised { @executor.send(:ensure_disk_space!) }
      assert_match "Free disk space", @run.logs.last.message
    end

    test "without a previous dump only the reserve is required" do
      free_disk(2.gigabytes)
      assert_nothing_raised { @executor.send(:ensure_disk_space!) }

      free_disk(512.megabytes)
      assert_raises(Backups::Error) { @executor.send(:ensure_disk_space!) }
    end

    test "an unknown free space never blocks the dump" do
      free_disk(nil)

      assert_nothing_raised { @executor.send(:ensure_disk_space!) }
      @executor.send(:check_disk_space)
      assert_nil @executor.instance_variable_get(:@disk_shortage)
    end

    test "flags a shortage once free space drops below the reserve" do
      free_disk(5.gigabytes)
      @executor.send(:check_disk_space)
      assert_nil @executor.instance_variable_get(:@disk_shortage)

      free_disk(100.megabytes)
      @executor.send(:check_disk_space)
      assert_equal 100.megabytes, @executor.instance_variable_get(:@disk_shortage)
    end

    test "picks up a cancel request made by another process" do
      @executor.send(:check_cancel_request)
      assert_not @executor.instance_variable_get(:@cancel_requested)

      BackupRun.find(@run.id).request_cancel!(by: "Alice")
      @executor.send(:check_cancel_request)
      assert @executor.instance_variable_get(:@cancel_requested)
    end

    private

    def completed_run(size_bytes:)
      @run.backup_routine.runs.create!(status: :completed, trigger: :scheduled,
                                       finished_at: 1.day.ago, size_bytes: size_bytes)
    end

    def free_disk(bytes)
      @executor.define_singleton_method(:free_disk_bytes) { bytes }
    end

    def table_log_lines
      @run.logs.pluck(:message).grep(/\ADumping table/)
    end
  end
end
