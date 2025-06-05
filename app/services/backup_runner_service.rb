class BackupRunnerService < ApplicationService
  attr_reader :backup_routine, :run

  def initialize(backup_routine)
    @backup_routine = backup_routine
    @run = backup_routine.runs.create!(status: :running, started_at: Time.current)
  end

  def call
    log_info("Created backup run with ID: #{run.id}")

    file_path = DatabaseDumpService.call(run, backup_routine)
    log_info("Dump file created at: #{file_path}")

    file_url = StorageUploadService.call(backup_routine.destination, file_path)
    log_info("File uploaded to: #{file_url}")

    run.update!(status: :completed, finished_at: Time.current, file_url:)

    log_info("Backup process completed successfully.")

    true
  rescue => e
    run&.update(status: :failed, finished_at: Time.current)
    log_error("Backup process failed: #{e.message}")
    raise e
  end
end
