require 'open3'

class DatabaseDumpService < ApplicationService
  attr_reader :backup_run, :routine, :connection, :filename, :filepath

  def initialize(backup_run, backup_routine)
    @backup_run = backup_run
    @routine = backup_routine
    @connection = backup_routine.database_connection

    @filename = "backup-#{connection.database_name}-#{backup_run.started_at.to_s.parameterize}.dump"
    @filepath = Rails.root.join("tmp", filename)
  end

  def call
    log_info("Starting DB dump for database: #{connection.database_name}")

    log_info("Executing command: #{dump_command}")

    ENV["PGPASSWORD"] = connection.password
    stdout, stderr, status = Open3.capture3(*dump_command)

    if status.success?
      log_info("Backup completed successfully. Command output:\n#{stderr}")
      log_info(stdout)
      filepath
    else
      raise StandardError,stderr
    end

  rescue => e
    backup_run.update!(status: :failed, finished_at: Time.current)
    raise e

  ensure
    ENV["PGPASSWORD"] = nil
  end

  private

  def dump_command
    cmd = [
      "pg_dump",
      "--host", connection.host,
      "--port", connection.port.to_s,
      "--username", connection.username,
      "--dbname", connection.database_name,
      "--file", filepath.to_s,
      "--format custom",
      "--verbose"
    ]

    cmd << "--no-owner" if routine.no_owner
    cmd << "--no-privileges" if routine.no_privileges

    routine.tables_to_exclude&.split(',')&.each do |table|
      cmd << "--exclude-table=#{table.strip}"
    end if routine.tables_to_exclude.present?

    routine.tables_to_exclude_data&.split(',')&.each do |table|
      cmd << "--exclude-table-data=#{table.strip}"
    end if routine.tables_to_exclude_data.present?

    cmd.join(' ')
  end
end
