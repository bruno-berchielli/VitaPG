---
name: create-self-refreshing-component
description: Pattern for creating components that require updates (Turbo Streams), both async (broadcasts) and sync (controller renders). Use for anything showing live state — run status, logs, dashboards.
---

# Create Self-Refreshing Component

Use this skill when implementing components that need to update via Turbo Streams, effectively replacing `turbo_stream` partials with encapsulated component logic. Broadcasts ride on Solid Cable — no Redis.

## Core Philosophy

1. **Encapsulation**: The component is responsible for knowing its own DOM `:id` and ActionCable `:broadcast_channel`. This avoids "magic strings" scattered across views and controllers.
2. **No Partials**: Do NOT use `partial: "path/to/partial"`. Use `renderable: self` or pass the component instance directly.
3. **Locality of Behavior**: Keep the logic for refreshing the component inside the component class itself.

## Implementation Template

```ruby
class BackupRuns::StatusCardComponent < ApplicationComponent
  def initialize(backup_run:)
    @backup_run = backup_run
  end

  # 1. Encapsulate the ID. Use a class method so a stale DOM id can be
  #    targeted even when the record instance is not at hand.
  def self.dom_id_for(backup_run_id)
    "backup_run_status_card_#{backup_run_id}"
  end

  def id
    self.class.dom_id_for(@backup_run.id)
  end

  # 2. Encapsulate the Channel
  def broadcast_channel
    [@backup_run, :status_card_refresh]
  end

  # 3. The Async Refresh Method (Background Jobs)
  def broadcast_refresh!
    Turbo::StreamsChannel.broadcast_replace_to(
      broadcast_channel,
      target: id,
      renderable: self,
      layout: false
    )
  end
end
```

## Usage 1: Background Job (Async Broadcast)

Use `broadcast_refresh!` when the update happens out-of-band (e.g., a backup run advances status inside a job):

```ruby
# app/jobs/run_backup_job.rb (or the service it calls)
BackupRuns::StatusCardComponent.new(backup_run: run).broadcast_refresh!
```

## Usage 2: Controller Action (Sync Render)

When inside a controller request (e.g., form submission), do **NOT** broadcast. Render the replacement synchronously — faster and no cable round-trip:

```ruby
def create
  @run = @routine.run_later!

  render turbo_stream: turbo_stream.replace(status_card.id, status_card)
end

private

def status_card
  @status_card ||= BackupRuns::StatusCardComponent.new(backup_run: @run)
end
```

## View Implementation (.html.erb)

Only connect to the stream if you actually expect async updates (e.g., conditional on state):

```erb
<%= tag.div id: id do %>
  <% if @backup_run.in_progress? %>
    <%= helpers.turbo_stream_from broadcast_channel %>
  <% end %>
  <%# ... content ... %>
<% end %>
```
