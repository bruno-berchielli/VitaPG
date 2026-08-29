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

    finished_30d = runs.finished.where(created_at: 30.days.ago..)
    @finished_30d_count = finished_30d.count
    @success_rate_30d = @finished_30d_count.zero? ? nil : (finished_30d.completed.count * 100.0 / @finished_30d_count)

    @recent_runs = runs.includes(backup_routine: :database_connection).order(created_at: :desc).limit(8)
    @routine_health = routines.includes(:database_connection).order(:name).limit(6).map do |routine|
      [ routine, routine.last_run ]
    end
  end
end
