# frozen_string_literal: true

class Layout::TopbarComponent < ApplicationComponent
  EVENT_LIMIT = 8

  def initialize(query: nil)
    @query = query
  end

  def query = @query

  # The bell feed: latest finished runs across the workspace, newest first.
  def recent_events
    @recent_events ||= BackupRun.finished
                                .joins(:backup_routine)
                                .where(backup_routines: { workspace_id: Current.workspace.id })
                                .includes(:backup_routine)
                                .order(finished_at: :desc)
                                .limit(EVENT_LIMIT)
  end

  def attention?
    recent_events.any? { |run| run.failed? && run.finished_at&.after?(24.hours.ago) }
  end
end
