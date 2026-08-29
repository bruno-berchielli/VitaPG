# frozen_string_literal: true

module Notifications
  class MissedRunSlackNotifier < ApplicationService
    include HttpDelivery

    attr_reader :channel, :routine, :expected_at_iso

    def initialize(channel, routine, expected_at_iso)
      @channel = channel
      @routine = routine
      @expected_at_iso = expected_at_iso
    end

    def call
      text = ":warning: Backup *#{routine.name}* did NOT run as scheduled " \
             "(expected #{expected_at_iso}, cron `#{routine.cron}`). Check the scheduler."

      post_json!(channel.url, { text: text }.to_json)
    end
  end
end
