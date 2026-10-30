# Installs upgraded from the pre-encryption era have credentials stored in
# plain text. support_unencrypted_data lets the models read them; this
# migration rewrites every row through Active Record Encryption so nothing
# stays in plain text. No-op on fresh databases.
#
# Uses its own models: the app models declare columns (connection_mode,
# base_path, ...) that later migrations add, so loading them here fails.
class EncryptLegacyCredentials < ActiveRecord::Migration[8.1]
  class LegacyDatabaseConnection < ActiveRecord::Base
    self.table_name = "database_connections"
    encrypts :password
  end

  class LegacyDestination < ActiveRecord::Base
    self.table_name = "destinations"
    self.inheritance_column = nil
    encrypts :secret_access_key
  end

  def up
    LegacyDatabaseConnection.reset_column_information
    LegacyDestination.reset_column_information
    LegacyDatabaseConnection.find_each(&:encrypt)
    LegacyDestination.find_each(&:encrypt)
  end

  def down
    # Encrypted data stays encrypted.
  end
end
