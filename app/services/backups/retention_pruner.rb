# frozen_string_literal: true

module Backups
  # Applies a routine's retention policy. Deletion is strictly limited to
  # object keys recorded on this routine's own completed runs — the app never
  # lists or deletes anything else in the destination.
  class RetentionPruner < ApplicationService
    attr_reader :routine

    def initialize(routine)
      @routine = routine
    end

    def call
      candidates = prunable_runs
      return 0 if candidates.empty?

      adapter = routine.destination.adapter
      pruned = 0

      candidates.each do |run|
        adapter.delete!(run.file_key)
        run.update!(status: :pruned)
        run.log!(message: "Backup pruned by retention policy")
        pruned += 1
      rescue => e
        run.log!(message: "Retention pruning failed: #{e.message.to_s.first(500)}", status: :warning)
        Rails.error.report(e, context: { backup_run_id: run.id }, source: "backups")
      end

      pruned
    end

    private

    def prunable_runs
      runs = routine.runs.prunable.order(created_at: :desc)
      to_prune = []

      if routine.retention_keep_last.present?
        to_prune += runs.offset(routine.retention_keep_last)
      end

      if routine.retention_max_age_days.present?
        to_prune += runs.where(created_at: ...routine.retention_max_age_days.days.ago)
      end

      to_prune.uniq
    end
  end
end
