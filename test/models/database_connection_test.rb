require "test_helper"

class DatabaseConnectionTest < ActiveSupport::TestCase
  setup do
    @connection = database_connections(:prod)
  end

  test "ssh tunnel mode requires ssh host and user" do
    @connection.connection_mode = "ssh_tunnel"

    assert_not @connection.valid?
    assert @connection.errors[:ssh_host].any?
    assert @connection.errors[:ssh_user].any?
  end

  test "switching to ssh tunnel generates an app-owned keypair" do
    @connection.update!(connection_mode: "ssh_tunnel", ssh_host: "server.example.com", ssh_user: "deploy")

    assert_match(/\A-----BEGIN (RSA )?PRIVATE KEY-----/, @connection.ssh_private_key)
    assert_match(/\Assh-rsa AAAA[A-Za-z0-9+\/=]+ vitapg\z/, @connection.ssh_public_key)

    raw = ActiveRecord::Base.connection.select_value(
      "SELECT ssh_private_key FROM database_connections WHERE id = #{@connection.id}"
    )
    assert raw.start_with?("{"), "private key must be encrypted at rest"
  end

  test "keypair is kept when the record is saved again" do
    @connection.update!(connection_mode: "ssh_tunnel", ssh_host: "server.example.com", ssh_user: "deploy")
    original = @connection.ssh_public_key

    @connection.update!(name: "Renamed")

    assert_equal original, @connection.reload.ssh_public_key
  end

  test "with_pg_env yields the plain env for direct connections" do
    @connection.with_pg_env do |env|
      assert_equal "db.example.com", env["PGHOST"]
      assert_equal "5432", env["PGPORT"]
    end
  end

  test "with_pg_env rewrites host and port to the tunnel's local end" do
    @connection.update!(connection_mode: "ssh_tunnel", ssh_host: "server.example.com", ssh_user: "deploy")

    original = Backups::SshTunnel.method(:open)
    Backups::SshTunnel.define_singleton_method(:open) { |_conn, &block| block.call(54_321) }

    @connection.with_pg_env do |env|
      assert_equal "127.0.0.1", env["PGHOST"]
      assert_equal "54321", env["PGPORT"]
      assert_equal "secret", env["PGPASSWORD"]
    end
  ensure
    Backups::SshTunnel.define_singleton_method(:open, original) if original
  end
end
