class DatabaseConnectionsController < ApplicationController
  before_action :set_connection, only: %i[edit update destroy test reset_ssh_host_key]

  def index
    @connections = Current.workspace.database_connections.order(:name)
  end

  def new
    @connection = Current.workspace.database_connections.new(port: 5432)
  end

  def create
    @connection = Current.workspace.database_connections.new(connection_params)

    if @connection.save
      redirect_to database_connections_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @connection.update(connection_params_for_update)
      redirect_to database_connections_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @connection.destroy
      redirect_to database_connections_path, notice: t(".destroyed")
    else
      redirect_to database_connections_path, alert: @connection.errors.full_messages.to_sentence
    end
  end

  def test
    result = DatabaseConnections::Tester.call(@connection)

    if result.success?
      redirect_back fallback_location: database_connections_path, notice: t(".success")
    else
      redirect_back fallback_location: database_connections_path, alert: t(".failure", message: result.message)
    end
  end

  # A reinstalled server presents a new host key; the pinned one must be
  # cleared explicitly so a silent MITM can never look like a reinstall.
  def reset_ssh_host_key
    @connection.update_column(:ssh_known_host_key, nil)
    redirect_to edit_database_connection_path(@connection), notice: t(".reset")
  end

  private

  def set_connection
    @connection = Current.workspace.database_connections.find(params[:id])
  end

  def connection_params
    params.expect(database_connection: %i[name host port username password database_name sslmode
                                          connection_mode ssh_host ssh_port ssh_user])
  end

  # A blank password on edit means "keep the current one" — secrets are write-only in the UI.
  def connection_params_for_update
    permitted = connection_params
    permitted.delete(:password) if permitted[:password].blank?
    permitted
  end
end
