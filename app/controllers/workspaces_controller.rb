class WorkspacesController < ApplicationController
  before_action :require_workspace_manager!, only: %i[edit update]

  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new(workspace_params)

    ApplicationRecord.transaction do
      @workspace.save!
      @workspace.memberships.create!(user: current_user, role: :owner)
    end

    session[:workspace_id] = @workspace.id
    redirect_to root_path, notice: t(".created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
    @workspace = Current.workspace
  end

  def update
    @workspace = Current.workspace

    if @workspace.update(workspace_params)
      redirect_to edit_workspace_path(@workspace), notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def switch
    workspace = current_user.workspaces.find(params[:id])
    session[:workspace_id] = workspace.id
    redirect_to root_path
  end

  private

  def workspace_params
    params.expect(workspace: [ :name ])
  end
end
