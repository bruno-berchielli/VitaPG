# frozen_string_literal: true

module Notifications
  # Fans out a finished run to every workspace channel that wants it.
  # Enqueued per channel so one slow endpoint never delays another.
  class Dispatcher < ApplicationService
    attr_reader :run

    def initialize(run)
      @run = run
    end

    def call
      run.workspace.notification_channels.enabled.each do |channel|
        next unless channel.notifies?(run)

        NotifyRunJob.perform_later(channel.id, run.id)
      end
    end
  end
end
