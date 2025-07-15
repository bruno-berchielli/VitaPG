class GoogleAuthController < ApplicationController
  def start
    unless params[:destination_id]
      redirect_to "/admin/resources/destinations", alert: "No destination selected"
      return
    end

    destination = Destination.find(params[:destination_id])
    session[:destination_id] = destination.id

    client = Signet::OAuth2::Client.new(
      client_id: destination.client_id,
      client_secret: destination.client_secret,
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      scope: "https://www.googleapis.com/auth/drive.file",
      redirect_uri: ENV["GOOGLE_DRIVE_REDIRECT_URI"],
      access_type: "offline",
      prompt: "consent"
    )

    redirect_to client.authorization_uri.to_s, allow_other_host: true
  end

  def callback
    Rails.logger.info "🚨 Google OAuth callback params: #{params.to_unsafe_h.inspect}"

    destination = Destination.find(session[:destination_id])
    code = params[:code]

    client = Signet::OAuth2::Client.new(
      client_id: destination.client_id,
      client_secret: destination.client_secret,
      token_credential_uri: "https://oauth2.googleapis.com/token",
      redirect_uri: ENV["GOOGLE_DRIVE_REDIRECT_URI"],
      code: code
    )

    client.fetch_access_token!

    destination.update!(
      access_token: client.access_token,
      refresh_token: client.refresh_token,
      expires_at: Time.current + client.expires_in
    )

    redirect_to "/admin/data/destinations", notice: "Google Drive connected!"

  rescue Signet::AuthorizationError => e
    Rails.logger.error "Google Auth Error: #{e.message}"
    redirect_to "/admin/data/destinations", alert: "Google authorization failed. Please try again."
  end
end
