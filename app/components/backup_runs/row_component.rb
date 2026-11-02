# frozen_string_literal: true

# One row in a runs table. Self-refreshing: subscribes while the run is in
# progress so status flips live without a page reload.
#
# The broadcast is shared by every table showing the run, so the row always
# carries the routine cell; tables scoped to one routine hide it with
# data-hide-routine.
class BackupRuns::RowComponent < ApplicationComponent
  with_collection_parameter :run

  def initialize(run:)
    @run = run
  end

  def self.dom_id_for(run_id)
    "backup_run_row_#{run_id}"
  end

  def id
    self.class.dom_id_for(@run.id)
  end

  def broadcast_refresh!
    Turbo::StreamsChannel.broadcast_replace_to(
      @run.updates_channel,
      target: id,
      renderable: self,
      layout: false
    )
  end

  def routine = @run.backup_routine
end
