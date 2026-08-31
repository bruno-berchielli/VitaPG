require "test_helper"

module Backups
  class SshTunnelTest < ActiveSupport::TestCase
    setup do
      @connection = database_connections(:prod)
      @connection.update!(connection_mode: "ssh_tunnel", ssh_host: "server.example.com", ssh_user: "deploy")
      @verifier = SshTunnel::HostKeyVerifier.new(@connection)
    end

    test "host key is pinned on first use and accepted when unchanged" do
      blob = "host-key-blob"

      assert @verifier.verify({ key_blob: blob })
      assert_equal [ blob ].pack("m0"), @connection.reload.ssh_known_host_key
      assert @verifier.verify({ key_blob: blob })
    end

    test "a changed host key aborts instead of connecting" do
      @verifier.verify({ key_blob: "original-key" })

      error = assert_raises(Backups::Error) { @verifier.verify({ key_blob: "attacker-key" }) }
      assert_match(/host key mismatch/i, error.message)
    end
  end
end
