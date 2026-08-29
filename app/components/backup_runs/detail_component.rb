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

  # The restore command matching this run's dump format. Never suggests
  # destructive flags (--clean/--create drop objects).
  def restore_command
    return unless run.completed? && run.file_key.present?

    filename = File.basename(run.file_key)

    case filename
    when /\.dump\z/ then "pg_restore --dbname=YOUR_DATABASE #{filename}"
    when /\.sql\.gz\z/ then "gunzip -c #{filename} | psql --dbname=YOUR_DATABASE"
    when /\.sql\z/ then "psql --dbname=YOUR_DATABASE --file=#{filename}"
    when /\.tar\z/ then "tar -xf #{filename} && pg_restore --dbname=YOUR_DATABASE dump"
    end
  end

  def facts
    [
      [ t(".started"), run.started_at ? helpers.relative_time(run.started_at) : "—" ],
      [ t(".duration"), helpers.human_duration(run.duration) ],
      [ t(".size"), helpers.human_size(run.size_bytes) ],
      [ t(".trigger"), t(".triggers.#{run.trigger}") ]
    ]
  end
end
