class NotificationChannelsController < ApplicationController
  before_action :require_workspace_manager!, except: :index
  before_action :set_channel, only: %i[edit update destroy]

  def index
    @channels = Current.workspace.notification_channels.order(:name)
  end

  def new
    @channel = Current.workspace.notification_channels.new(kind: "email")
  end

  def create
    @channel = Current.workspace.notification_channels.new(channel_params)

    if @channel.save
      redirect_to notification_channels_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @channel.update(channel_params_for_update)
      redirect_to notification_channels_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @channel.destroy
    redirect_to notification_channels_path, notice: t(".destroyed")
  end

  private

  def set_channel
    @channel = Current.workspace.notification_channels.find(params[:id])
  end

  def channel_params
    params.expect(notification_channel: %i[name kind url recipients notify_on_success notify_on_failure enabled])
  end

  def channel_params_for_update
    permitted = channel_params
    permitted.delete(:url) if permitted[:url].blank?
    permitted
  end
end
