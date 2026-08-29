# frozen_string_literal: true

module Backups
  # Dead-man's switch: notices routines whose scheduled run never happened
  # (crashed worker, deleted recurring task, stopped host) — the failure mode
  # ordinary monitoring can't see because nothing errored.
  class MissedRunChecker < ApplicationService
    GRACE = 30.minutes

    attr_reader :routine, :now

    def initialize(routine, now: Time.current)
      @routine = routine
      @now = now
    end

    # @return [Boolean] whether a missed-run alert was raised
    def call
      return false unless routine.enabled?

      expected_at = last_expected_run_at
      return false if expected_at.nil? || now < expected_at + GRACE
      return false if routine.runs.where(created_at: expected_at..).exists?
      return false if routine.last_missed_alert_at.present? && routine.last_missed_alert_at >= expected_at

      routine.update!(last_missed_alert_at: now)
      Notifications::MissedRunDispatcher.call(routine, expected_at)
      true
    end

    private

    def last_expected_run_at
      cron = Fugit.parse_cron(routine.cron_with_timezone)
      cron&.previous_time(now)&.to_t
    end
  end
end
