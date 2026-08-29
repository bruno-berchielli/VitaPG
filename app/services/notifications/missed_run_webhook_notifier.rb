# frozen_string_literal: true

module Notifications
  class MissedRunWebhookNotifier < ApplicationService
    include HttpDelivery

    attr_reader :channel, :routine, :expected_at_iso

    def initialize(channel, routine, expected_at_iso)
      @channel = channel
      @routine = routine
      @expected_at_iso = expected_at_iso
    end

    def call
      body = {
        event: "backup.missed",
        workspace: routine.workspace.slug,
        routine: { id: routine.id, name: routine.name },
        expected_at: expected_at_iso,
        cron: routine.cron,
        database: routine.database_connection.database_name
      }.to_json

      timestamp = Time.current.to_i
      signature = OpenSSL::HMAC.hexdigest("SHA256", channel.signing_secret.to_s, "#{timestamp}.#{body}")

      post_json!(channel.url, body, "X-Vitapg-Signature" => "t=#{timestamp},v1=#{signature}")
    end
  end
end
