# Credentials at rest (database passwords, storage keys) are encrypted with
# Active Record Encryption. Keys can be provided explicitly via environment
# variables; otherwise they are derived deterministically from secret_key_base
# so a self-hosted install works with zero extra configuration. Rotating
# SECRET_KEY_BASE therefore invalidates stored credentials — set the explicit
# variables before rotating if you need to keep them.
Rails.application.configure do
  derive = ->(salt) { Rails.application.key_generator.generate_key(salt, 32).unpack1("H*") }

  config.active_record.encryption.primary_key =
    ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY") { derive.call("active_record_encryption/primary") }
  config.active_record.encryption.deterministic_key =
    ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY") { derive.call("active_record_encryption/deterministic") }
  config.active_record.encryption.key_derivation_salt =
    ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT") { derive.call("active_record_encryption/derivation_salt") }
end
