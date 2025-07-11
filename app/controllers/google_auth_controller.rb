class GoogleAuthController < ApplicationController
  def start
    client = Signet::OAuth2::Client.new(
      client_id: client.client_id,
      client_secret: client.client_secret,
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

    code = params[:code]

    client = Signet::OAuth2::Client.new(
      client_id: client.client_id,
      client_secret: client.client_secret,
      token_credential_uri: "https://oauth2.googleapis.com/token",
      redirect_uri: ENV["GOOGLE_DRIVE_REDIRECT_URI"],
      code: code
    )

    client.fetch_access_token!

    Destination.create!(
      name: client.name,
      provider: client.provider,
      client_id: client.client_id,
      client_secret: client.client_secret,
      access_token: client.access_token,
      refresh_token: client.refresh_token,
      expires_at: Time.now + client.expires_in,
      folder_id: nil
    )

    # redirect_to "/admin"
    redirect_to "/admin/resources/destinations", notice: "Google Drive connected!"
  end
end
