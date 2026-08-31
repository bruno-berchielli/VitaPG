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

    private

    def table_log_lines
      @run.logs.pluck(:message).grep(/\ADumping table/)
    end
  end
end
