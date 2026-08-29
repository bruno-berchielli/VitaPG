class BackupRoutinesController < ApplicationController
  before_action :set_routine, only: %i[show edit update destroy run toggle]

  def index
    @routines = Current.workspace.backup_routines
                       .includes(:database_connection, :destination)
                       .order(:name)
  end

  def show
    @runs = @routine.runs.order(created_at: :desc).limit(30)
  end

  def new
    @routine = Current.workspace.backup_routines.new
  end

  def create
    @routine = Current.workspace.backup_routines.new(routine_params)

    if @routine.save
      redirect_to backup_routine_path(@routine), notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @routine.update(routine_params)
      redirect_to backup_routine_path(@routine), notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @routine.destroy
    redirect_to backup_routines_path, notice: t(".destroyed")
  end

  def run
    if @routine.running?
      redirect_to backup_routine_path(@routine), alert: t(".already_running")
    else
      run = @routine.run_later!
      redirect_to backup_run_path(run), notice: t(".started")
    end
  end

  def toggle
    @routine.update!(enabled: !@routine.enabled?)
    redirect_back fallback_location: backup_routines_path,
                  notice: @routine.enabled? ? t(".enabled") : t(".disabled")
  end

  private

  def set_routine
    @routine = Current.workspace.backup_routines.find(params[:id])
  end

  def routine_params
    permitted = params.expect(backup_routine: %i[
      name database_connection_id destination_id cron schedule_timezone
      format compression_level parallel_jobs retention_keep_last
      retention_max_age_days path_prefix tables_to_exclude
      tables_to_exclude_data no_owner no_privileges enabled
    ])

    # A routine may only reference resources inside the current workspace.
    permitted[:database_connection_id] = Current.workspace.database_connections.find(permitted[:database_connection_id]).id if permitted[:database_connection_id].present?
    permitted[:destination_id] = Current.workspace.destinations.find(permitted[:destination_id]).id if permitted[:destination_id].present?
    permitted
  end
end
