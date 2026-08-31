module DatabaseConnectionsHelper
  # One-liner shown on the SSH setup step. The public key is app-generated
  # base64 (no quotes to escape).
  def authorized_keys_command(connection)
    "echo '#{connection.ssh_public_key}' >> ~/.ssh/authorized_keys"
  end
end
