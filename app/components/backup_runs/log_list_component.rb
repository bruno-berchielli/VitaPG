# frozen_string_literal: true

# Terminal-style log view. New lines are appended live via the run's log
# channel while the run is in progress.
class BackupRuns::LogListComponent < ApplicationComponent
  def initialize(run:, logs: nil)
    @run = run
    @logs = logs
  end

  def self.list_dom_id_for(run_id)
    "backup_run_log_list_#{run_id}"
  end

  # Called from BackupLog after creation (out-of-band, from the job process).
  def self.broadcast_line!(log)
    Turbo::StreamsChannel.broadcast_append_to(
      log.backup_run.updates_channel,
      target: list_dom_id_for(log.backup_run_id),
      renderable: BackupRuns::LogLineComponent.new(log: log),
      layout: false
    )
  end

  def list_id = self.class.list_dom_id_for(@run.id)

  def logs
    @logs || @run.logs.order(:id)
  end

  def run = @run
end
