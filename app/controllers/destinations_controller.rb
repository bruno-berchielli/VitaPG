class DestinationsController < ApplicationController
  before_action :set_destination, only: %i[edit update destroy test]

  def index
    @destinations = Current.workspace.destinations.order(:name)
  end

  def new
    @destination = Current.workspace.destinations.new
  end

  def create
    @destination = Current.workspace.destinations.new(destination_params)

    if @destination.save
      redirect_to destinations_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @destination.update(destination_params_for_update)
      redirect_to destinations_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @destination.destroy
      redirect_to destinations_path, notice: t(".destroyed")
    else
      redirect_to destinations_path, alert: t(".in_use")
    end
  end

  def test
    result = Destinations::Tester.call(@destination)

    if result.success?
      redirect_back fallback_location: destinations_path, notice: t(".success")
    else
      redirect_back fallback_location: destinations_path, alert: t(".failure", message: result.message)
    end
  end

  private

  def set_destination
    @destination = Current.workspace.destinations.find(params[:id])
  end

  def destination_params
    params.expect(destination: %i[name provider bucket region endpoint access_key_id secret_access_key])
  end

  def destination_params_for_update
    permitted = destination_params
    permitted.delete(:secret_access_key) if permitted[:secret_access_key].blank?
    permitted
  end
end
