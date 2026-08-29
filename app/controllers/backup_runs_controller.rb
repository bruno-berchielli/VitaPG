class BackupRunsController < ApplicationController
  before_action :set_run, only: %i[show download]

  PER_PAGE = 50

  def index
    scope = workspace_runs.includes(backup_routine: :database_connection)
                          .order(created_at: :desc)
    scope = scope.where(status: params[:status]) if BackupRun.statuses.key?(params[:status])

    @page = [ params[:page].to_i, 1 ].max
    @runs = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @has_next_page = @runs.size > PER_PAGE
    @runs = @runs.first(PER_PAGE)
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
