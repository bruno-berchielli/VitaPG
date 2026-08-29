# frozen_string_literal: true

# Status panel on the run page. Self-refreshing while the run is in progress.
class BackupRuns::DetailComponent < ApplicationComponent
  def initialize(run:)
    @run = run
  end

  def self.dom_id_for(run_id)
    "backup_run_detail_#{run_id}"
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

  def run = @run

  def facts
    [
      [ t(".started"), run.started_at ? helpers.relative_time(run.started_at) : "—" ],
      [ t(".duration"), helpers.human_duration(run.duration) ],
      [ t(".size"), helpers.human_size(run.size_bytes) ],
      [ t(".trigger"), t(".triggers.#{run.trigger}") ]
    ]
  end
end
