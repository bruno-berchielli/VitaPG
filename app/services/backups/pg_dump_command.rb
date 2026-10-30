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

      # Extension config tables (e.g. pg_cron's cron.job) ignore
      # --exclude-table and are only skipped via --exclude-table-data, so an
      # excluded table always gets both flags.
      excluded_tables.each { |table| cmd << "--exclude-table=#{table}" }
      (excluded_tables | excluded_data_tables).each { |table| cmd << "--exclude-table-data=#{table}" }

      cmd
    end

    # Redacted-safe: contains no credentials by construction.
    def to_log_line
      argv.join(" ")
    end

    # Size of the table data pg_dump will actually read: heap and TOAST of
    # every user table, leaving out indexes (dumped as DDL only) and tables
    # whose data is excluded. Patterns follow pg_dump's rules: unquoted names
    # fold to lower case, `*` and `?` are wildcards.
    def source_size_sql
      <<~SQL.squish
        SELECT COALESCE(sum(pg_table_size(c.oid)), 0)
        FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r', 'm')
          AND n.nspname NOT IN ('pg_catalog', 'information_schema')
          AND n.nspname NOT LIKE 'pg\\_toast%' AND n.nspname NOT LIKE 'pg\\_temp%'
          #{(excluded_tables | excluded_data_tables).map { |pattern| "AND NOT (#{pattern_condition(pattern)})" }.join(" ")}
      SQL
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
      value.to_s.split(",").map(&:strip).reject(&:blank?).uniq
    end

    def pattern_condition(pattern)
      parts = pattern.scan(/"(?:[^"]|"")*"|[^.]+/)
      table = like_literal(parts.last)
      return "c.relname LIKE #{table}" if parts.one?

      "n.nspname LIKE #{like_literal(parts.first)} AND c.relname LIKE #{table}"
    end

    def like_literal(name)
      name = name.start_with?('"') ? name[1..-2].gsub('""', '"') : name.downcase
      like = name.gsub(/[\\%_]/) { "\\#{it}" }.tr("*?", "%_")
      "'#{like.gsub("'", "''")}'"
    end
  end
end
