class DashboardController < ApplicationController
  def show
    routines = Current.workspace.backup_routines
    runs = BackupRun.joins(:backup_routine).where(backup_routines: { workspace_id: Current.workspace.id })

    @routines_count = routines.count
    @enabled_count = routines.enabled.count
    @runs_last_24h = runs.where(created_at: 24.hours.ago..)
    @completed_last_24h = @runs_last_24h.completed.count
    @failed_last_24h = @runs_last_24h.failed.count
    @stored_bytes = runs.completed.sum(:size_bytes)
    @recent_runs = runs.includes(backup_routine: :database_connection).order(created_at: :desc).limit(10)
    @failing_routines = routines.includes(:database_connection)
                                .select { |r| r.last_run&.failed? }
  end
end
