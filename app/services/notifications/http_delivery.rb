# frozen_string_literal: true

require "net/http"

module Notifications
  # Shared HTTP POST with strict timeouts. Raises on non-2xx so NotifyRunJob's
  # retry policy applies.
  module HttpDelivery
    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 10

    def post_json!(url, body, headers = {})
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" }.merge(headers))
      request.body = body

      response = http.request(request)
      raise Backups::Error, "Notification endpoint responded #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response
    end

    def run_payload(run)
      routine = run.backup_routine
      {
        event: run.completed? ? "backup.completed" : "backup.failed",
        workspace: routine.workspace.slug,
        routine: { id: routine.id, name: routine.name },
        run: {
          id: run.id,
          status: run.status,
          trigger: run.trigger,
          started_at: run.started_at&.iso8601,
          finished_at: run.finished_at&.iso8601,
          duration_seconds: run.duration&.round,
          size_bytes: run.size_bytes,
          database: routine.database_connection.database_name,
          destination: routine.destination.name,
          error: run.error_message&.first(500)
        }
      }
    end
  end
end
