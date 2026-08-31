require "test_helper"

class BackupRoutineTest < ActiveSupport::TestCase
  test "exclusion lists are normalized: whitespace, empty entries and duplicates" do
    routine = backup_routines(:nightly)
    routine.update!(
      tables_to_exclude: "  cron.job ,, cron.job ,public.logs  ",
      tables_to_exclude_data: "   ,  "
    )

    assert_equal "cron.job, public.logs", routine.tables_to_exclude
    assert_nil routine.tables_to_exclude_data
  end
end
