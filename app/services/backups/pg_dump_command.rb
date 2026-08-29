# frozen_string_literal: true

module Backups
  # Builds the pg_dump argv for a routine. Pure — no execution, no credentials
  # (those travel via the process environment), so it is fully unit-testable.
  class PgDumpCommand
    attr_reader :routine

    def initialize(routine, output_path:)
      @routine = routine
      @output_path = output_path
    end

    def argv
      cmd = [ "pg_dump", "--format=#{pg_format}", "--file=#{@output_path}", "--verbose" ]

      cmd << "--compress=#{routine.compression_level}"
      cmd << "--jobs=#{routine.parallel_jobs}" if parallel?
      cmd << "--no-owner" if routine.no_owner
      cmd << "--no-privileges" if routine.no_privileges

      excluded_tables.each { |table| cmd << "--exclude-table=#{table}" }
      excluded_data_tables.each { |table| cmd << "--exclude-table-data=#{table}" }

      cmd
    end

    # Redacted-safe: contains no credentials by construction.
    def to_log_line
      argv.join(" ")
    end

    def file_extension
      case routine.format
      when "custom" then ".dump"
      when "directory" then ""
      when "plain" then routine.compression_level.positive? ? ".sql.gz" : ".sql"
      end
    end

    private

    def pg_format
      { "custom" => "custom", "plain" => "plain", "directory" => "directory" }.fetch(routine.format)
    end

    def parallel?
      routine.format == "directory" && routine.parallel_jobs > 1
    end

    def excluded_tables
      split_list(routine.tables_to_exclude)
    end

    def excluded_data_tables
      split_list(routine.tables_to_exclude_data)
    end

    def split_list(value)
      value.to_s.split(",").map(&:strip).reject(&:blank?)
    end
  end
end
