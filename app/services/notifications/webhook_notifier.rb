# frozen_string_literal: true

module Notifications
  # Signed webhook: receivers verify integrity with
  #   HMAC-SHA256(signing_secret, "#{timestamp}.#{raw_body}")
  # sent as "X-Vitapg-Signature: t=<unix>,v1=<hex>".
  class WebhookNotifier < ApplicationService
    include HttpDelivery

    attr_reader :channel, :run

    def initialize(channel, run)
      @channel = channel
      @run = run
    end

    def call
      body = run_payload(run).to_json
      timestamp = Time.current.to_i
      signature = OpenSSL::HMAC.hexdigest("SHA256", channel.signing_secret.to_s, "#{timestamp}.#{body}")

      post_json!(channel.url, body, "X-Vitapg-Signature" => "t=#{timestamp},v1=#{signature}")
    end
  end
end
