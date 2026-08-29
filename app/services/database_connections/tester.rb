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
      result = Backups::CommandRunner.run(
        [ "psql", "--no-psqlrc", "--tuples-only", "--command", "SELECT 1" ],
        env: connection.pg_env,
        timeout: 15
      )

      if result.timed_out
        Result.new(success: false, message: "Connection timed out after 15s")
      elsif result.success?
        Result.new(success: true, message: "Connection successful")
      else
        Result.new(success: false, message: result.stderr.to_s.first(500))
      end
    end
  end
end
