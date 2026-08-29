require "test_helper"

# Full pipeline against a real PostgreSQL and a real MinIO:
# dump -> upload -> verify -> retention. Gated behind INTEGRATION=1 so the
# regular suite stays dependency-free; CI provides the services.
#
# Locally:
#   docker run -d --rm -e POSTGRES_PASSWORD=postgres -p 55432:5432 postgres:17-alpine
#   docker run -d --rm -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin \
#     -p 59000:9000 bitnami/minio
#   INTEGRATION=1 PGPORT_INTEGRATION=55432 MINIO_PORT_INTEGRATION=59000 bin/rails test test/integration
class BackupPipelineIntegrationTest < ActiveSupport::TestCase
  def self.runnable?
    ENV["INTEGRATION"] == "1"
  end

  if runnable?
    PG_PORT = ENV.fetch("PGPORT_INTEGRATION", "5432")
    MINIO_PORT = ENV.fetch("MINIO_PORT_INTEGRATION", "9000")
    PG_PASSWORD = ENV.fetch("PGPASSWORD_INTEGRATION", "postgres")
    BUCKET = "vitapg-integration"

    setup do
      seed_source_database
      create_bucket

      workspace = workspaces(:acme)
      @connection = workspace.database_connections.create!(
        name: "integration", host: "127.0.0.1", port: PG_PORT, username: "postgres",
        password: PG_PASSWORD, database_name: "postgres", sslmode: "prefer"
      )
      @destination = workspace.destinations.create!(
        name: "integration-minio", provider: "s3_compatible", bucket: BUCKET, region: "us-east-1",
        endpoint: "http://127.0.0.1:#{MINIO_PORT}", access_key_id: "minioadmin", secret_access_key: "minioadmin"
      )
      @routine = workspace.backup_routines.create!(
        name: "Integration", database_connection: @connection, destination: @destination,
        cron: "0 3 * * *", retention_keep_last: 1
      )
    end

    test "dump, upload, verify, complete and prune for real" do
      first = @routine.runs.create!(status: :pending, trigger: :manual)
      assert Backups::Runner.call(first), first.reload.error_message

      first.reload
      assert first.completed?
      assert first.size_bytes.positive?
      assert_equal first.size_bytes, @destination.adapter.head_size(first.file_key)

      second = @routine.runs.create!(status: :pending, trigger: :manual)
      assert Backups::Runner.call(second)

      # retention_keep_last = 1 prunes the first run's object
      assert first.reload.pruned?
      assert_nil @destination.adapter.head_size(first.file_key)
      assert_equal second.reload.size_bytes, @destination.adapter.head_size(second.file_key)
    end

    test "bad credentials fail cleanly without leaking secrets" do
      @connection.update!(password: "wrong")
      run = @routine.runs.create!(status: :pending, trigger: :manual)

      assert_not Backups::Runner.call(run)
      run.reload
      assert run.failed?
      assert run.error_message.present?
      assert_no_match(/wrong/, run.error_message)
    end

    private

    def seed_source_database
      env = { "PGHOST" => "127.0.0.1", "PGPORT" => PG_PORT, "PGUSER" => "postgres",
              "PGPASSWORD" => PG_PASSWORD, "PGDATABASE" => "postgres" }
      result = Backups::CommandRunner.run(
        [ "psql", "--no-psqlrc", "--command",
          "CREATE TABLE IF NOT EXISTS items (id serial primary key, body text);
           INSERT INTO items (body) SELECT md5(random()::text) FROM generate_series(1, 5000);" ],
        env: env, timeout: 30
      )
      raise "seed failed: #{result.stderr}" unless result.success?
    end

    def create_bucket
      client = Aws::S3::Client.new(
        access_key_id: "minioadmin", secret_access_key: "minioadmin", region: "us-east-1",
        endpoint: "http://127.0.0.1:#{MINIO_PORT}", force_path_style: true
      )
      client.create_bucket(bucket: BUCKET)
    rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
      # already there
    end
  end
end
