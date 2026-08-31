# frozen_string_literal: true

require "net/ssh"

module Backups
  # Opens an SSH connection to the database's bastion/host and forwards a
  # local ephemeral port to the PostgreSQL address as seen from that server.
  # The block runs while the tunnel is up and receives the local port.
  #
  # Authentication is key-only (the app-generated keypair) and strictly
  # non-interactive. The server's host key is pinned on first use; a later
  # mismatch aborts the run instead of connecting.
  class SshTunnel
    CONNECT_TIMEOUT = 15

    def self.open(connection, &block)
      new(connection).open(&block)
    end

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def open
      session = Net::SSH.start(
        connection.ssh_host,
        connection.ssh_user,
        port: connection.ssh_port || 22,
        key_data: [ connection.ssh_private_key ],
        keys: [],
        keys_only: true,
        non_interactive: true,
        verify_host_key: HostKeyVerifier.new(connection),
        timeout: CONNECT_TIMEOUT,
        keepalive: true,
        keepalive_interval: 30
      )

      local_port = session.forward.local(0, connection.host, connection.port)
      stop = false
      pump = Thread.new do
        session.loop(0.1) { !stop }
      rescue IOError, Net::SSH::Disconnect
        # Session torn down while the loop was pumping — expected on close.
      end

      yield local_port
    ensure
      stop = true
      pump&.join(5)
      session&.close rescue nil
    end

    # Trust-on-first-use: the first successful connection pins the host key;
    # every later connection must present the same one.
    class HostKeyVerifier
      def initialize(connection)
        @connection = connection
      end

      def verify(arguments)
        presented = [ arguments[:key_blob] ].pack("m0")
        pinned = @connection.ssh_known_host_key

        if pinned.blank?
          @connection.pin_ssh_host_key!(presented)
          true
        elsif ActiveSupport::SecurityUtils.secure_compare(pinned, presented)
          true
        else
          raise Backups::Error, "SSH host key mismatch for #{@connection.ssh_host}: " \
            "the server's identity changed since it was first seen. If this is expected " \
            "(server reinstalled), clear the pinned host key on the connection."
        end
      end

      def verify_signature(&block)
        block.call
      end
    end
  end
end
