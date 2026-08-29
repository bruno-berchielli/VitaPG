# frozen_string_literal: true

module Notifications
  # Missed schedules go to every channel that listens for failures.
  class MissedRunDispatcher < ApplicationService
    attr_reader :routine, :expected_at

    def initialize(routine, expected_at)
      @routine = routine
      @expected_at = expected_at
    end

    def call
      routine.workspace.notification_channels.enabled.where(notify_on_failure: true).each do |channel|
        NotifyMissedRunJob.perform_later(channel.id, routine.id, expected_at.iso8601)
      end
    end
  end
end
