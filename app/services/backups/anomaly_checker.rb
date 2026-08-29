# frozen_string_literal: true

module Backups
  # Flags completed runs whose size deviates sharply from the routine's recent
  # history — a shrunken dump often means silent data loss upstream.
  class AnomalyChecker < ApplicationService
    MINIMUM_HISTORY = 3
    DEVIATION_THRESHOLD = 0.5

    attr_reader :run

    def initialize(run)
      @run = run
    end

    def call
      return false unless run.completed? && run.size_bytes.to_i.positive?

      history = run.backup_routine.runs
                   .where(status: %i[completed pruned])
                   .where.not(id: run.id)
                   .where.not(size_bytes: nil)
                   .order(created_at: :desc)
                   .limit(10)
                   .pluck(:size_bytes)

      return false if history.size < MINIMUM_HISTORY

      average = history.sum.to_f / history.size
      deviation = (run.size_bytes - average).abs / average

      return false if deviation <= DEVIATION_THRESHOLD

      run.log!(
        message: "Size anomaly: this backup is #{ActiveSupport::NumberHelper.number_to_human_size(run.size_bytes)}, " \
                 "#{(deviation * 100).round}% away from the recent average of " \
                 "#{ActiveSupport::NumberHelper.number_to_human_size(average)}",
        status: :warning
      )
      true
    end
  end
end
