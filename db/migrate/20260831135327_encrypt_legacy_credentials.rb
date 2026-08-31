# Installs upgraded from the pre-encryption era have credentials stored in
# plain text. support_unencrypted_data lets the models read them; this
# migration rewrites every row through Active Record Encryption so nothing
# stays in plain text. No-op on fresh databases.
class EncryptLegacyCredentials < ActiveRecord::Migration[8.1]
  def up
    DatabaseConnection.find_each(&:encrypt)
    Destination.find_each(&:encrypt)
  end

  def down
    # Encrypted data stays encrypted.
  end
end
