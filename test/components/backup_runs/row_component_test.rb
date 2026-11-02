# frozen_string_literal: true

require "test_helper"

class BackupRuns::RowComponentTest < ViewComponent::TestCase
  def test_the_broadcast_row_keeps_the_routine_cell
    run = backup_routines(:nightly).runs.create!(status: :dumping, trigger: :manual)

    render_inline(BackupRuns::RowComponent.new(run: run))

    assert_selector "tr##{BackupRuns::RowComponent.dom_id_for(run.id)} td a", text: run.backup_routine.name
  end
end
