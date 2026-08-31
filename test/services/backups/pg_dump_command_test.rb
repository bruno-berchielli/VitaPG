require "test_helper"

module Backups
  class PgDumpCommandTest < ActiveSupport::TestCase
    setup do
      @routine = backup_routines(:nightly)
    end

    test "builds a custom-format command with compression" do
      argv = PgDumpCommand.new(@routine, output_path: "/tmp/x.dump").argv

      assert_equal "pg_dump", argv.first
      assert_includes argv, "--format=custom"
      assert_includes argv, "--file=/tmp/x.dump"
      assert_includes argv, "--compress=6"
      assert_not argv.any? { |a| a.start_with?("--jobs") }
    end

    test "directory format supports parallel jobs and per-table compression" do
      @routine.assign_attributes(format: "directory", parallel_jobs: 4, compression_level: 9)
      argv = PgDumpCommand.new(@routine, output_path: "/tmp/dir").argv

      assert_includes argv, "--format=directory"
      assert_includes argv, "--jobs=4"
      assert_includes argv, "--compress=9"
    end

    test "maps exclusion lists and flags" do
      @routine.assign_attributes(tables_to_exclude: "logs, temp_stuff", tables_to_exclude_data: "audits", no_owner: true, no_privileges: true)
      argv = PgDumpCommand.new(@routine, output_path: "/tmp/x.dump").argv

      assert_includes argv, "--exclude-table=logs"
      assert_includes argv, "--exclude-table=temp_stuff"
      # Excluded tables also exclude data so extension config tables
      # (pg_cron's cron.job) are actually skipped.
      assert_includes argv, "--exclude-table-data=logs"
      assert_includes argv, "--exclude-table-data=temp_stuff"
      assert_includes argv, "--exclude-table-data=audits"
      assert_includes argv, "--no-owner"
      assert_includes argv, "--no-privileges"
    end

    test "never contains credentials" do
      line = PgDumpCommand.new(@routine, output_path: "/tmp/x.dump").to_log_line

      assert_no_match(/secret/, line)
      assert_no_match(/backup_reader/, line)
    end

    test "file extension follows format and compression" do
      assert_equal ".dump", PgDumpCommand.new(@routine, output_path: nil).file_extension

      @routine.format = "plain"
      assert_equal ".sql.gz", PgDumpCommand.new(@routine, output_path: nil).file_extension

      @routine.compression_level = 0
      assert_equal ".sql", PgDumpCommand.new(@routine, output_path: nil).file_extension

      @routine.format = "directory"
      assert_equal "", PgDumpCommand.new(@routine, output_path: nil).file_extension
    end
  end
end
