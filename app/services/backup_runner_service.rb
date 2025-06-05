class BackupRunnerService < ApplicationService
  attr_reader :backup_routine, :backup_run

  def initialize(backup_routine)
    @backup_routine = backup_routine
    @backup_run = backup_routine.runs.create!(status: :running, started_at: Time.current)
  end

  def call
    log_info("Created backup run with ID: #{backup_run.id}")

    file_path = DatabaseDumpService.call(backup_run, backup_routine)
    log_info("Dump file created at: #{file_path}")

    file_url = StorageUploadService.call(backup_routine.destination, file_path)
    log_info("File uploaded to: #{file_url}")

    backup_run.update!(status: :completed, finished_at: Time.current, file_url:)

    log_info("Backup process completed successfully.")

    true
  rescue => e
    backup_run&.update(status: :failed, finished_at: Time.current)
    log_error("Backup process failed: #{e.message}")
    raise e
  ensure
    if file_path && File.exist?(file_path)
      log_info("Cleaning up temporary file: #{file_path}")
      File.delete(file_path)
    end
  end
end
