# frozen_string_literal: true

module DatabaseConnections
  # Read-only connectivity check against a source database (SELECT 1 via psql).
  class Tester < ApplicationService
    Result = Data.define(:success, :message) do
      def success? = success
    end

    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def call
      result = connection.with_pg_env do |env|
        Backups::CommandRunner.run(
          [ "psql", "--no-psqlrc", "--tuples-only", "--command", "SELECT 1" ],
          env: env,
          timeout: 15
        )
      end

      if result.timed_out
        Result.new(success: false, message: "Connection timed out after 15s")
      elsif result.success?
        Result.new(success: true, message: "Connection successful")
      else
        Result.new(success: false, message: result.stderr.to_s.first(500))
      end
    rescue Backups::Error, Net::SSH::Exception, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT => e
      Result.new(success: false, message: e.message.to_s.first(500))
    end
  end
end
