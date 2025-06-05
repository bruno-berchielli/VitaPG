# app/services/database_dump_service.rb
class DatabaseDumpService
  def initialize(database_connection)
    @connection = database_connection
  end

  def call
    filename = "backup_#{@connection.database_name}_#{Time.now.strftime('%Y%m%d%H%M%S')}.dump"
    filepath = Rails.root.join("tmp", filename)

    cmd = [
      "pg_dump",
      "--host", @connection.host,
      "--port", @connection.port.to_s,
      "--username", @connection.username,
      "--dbname", @connection.database_name,
      "--file", filepath.to_s,
      "--format", "custom"
    ]

    ENV["PGPASSWORD"] = @connection.password

    success = system(*cmd)

    return filepath if success

    raise StandardError, "Database dump failed for #{@connection.name}"
  ensure
    ENV["PGPASSWORD"] = nil
  end
end
