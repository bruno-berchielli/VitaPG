class BackupRunsController < ApplicationController
  before_action :set_run, only: %i[show download]

  def index
    @runs = workspace_runs.includes(backup_routine: :database_connection)
                          .order(created_at: :desc)
    @runs = @runs.where(status: params[:status]) if BackupRun.statuses.key?(params[:status])
    @runs = @runs.limit(100)
  end

  def show
    @logs = @run.logs.order(:id)
  end

  def download
    url = @run.download_url

    if url
      redirect_to url, allow_other_host: true
    else
      redirect_to backup_run_path(@run), alert: t(".unavailable")
    end
  end

  private

  def workspace_runs
    BackupRun.joins(:backup_routine).where(backup_routines: { workspace_id: Current.workspace.id })
  end

  def set_run
    @run = workspace_runs.find(params[:id])
  end
end
