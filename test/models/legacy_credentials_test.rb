require "test_helper"

# Upgrade path from the pre-encryption era: rows written as plain text must
# stay readable and be rewritable as encrypted (what the
# EncryptLegacyCredentials migration does in production).
class LegacyCredentialsTest < ActiveSupport::TestCase
  test "plain-text passwords read fine and encrypt in place" do
    connection = database_connections(:prod)
    connection.update_columns(password: "legacy-plaintext")

    assert_equal "legacy-plaintext", connection.reload.password

    connection.encrypt

    raw = ActiveRecord::Base.connection.select_value(
      "SELECT password FROM database_connections WHERE id = #{connection.id}"
    )
    assert raw.start_with?("{"), "expected ciphertext envelope, got: #{raw[0, 20]}"
    assert_equal "legacy-plaintext", connection.reload.password
  end
end
