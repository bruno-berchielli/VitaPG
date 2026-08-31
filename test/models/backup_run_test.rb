require "test_helper"

class BackupRunTest < ActiveSupport::TestCase
  setup do
    @run = backup_routines(:nightly).runs.create!(status: :pending, trigger: :manual)
  end

  test "changing status stamps the stage start" do
    assert_not_nil @run.stage_started_at

    previous = @run.stage_started_at
    travel 2.minutes do
      @run.update!(status: :dumping)
      assert @run.stage_started_at > previous
    end
  end

  test "progress! stores KPIs and truncates the detail" do
    @run.update!(status: :dumping)
    @run.progress!(bytes: 1_000_000, rate_bps: 5_000, detail: "x" * 300)

    assert_equal 1_000_000, @run.progress_bytes
    assert_equal 5_000, @run.progress_rate_bps
    assert_equal 255, @run.progress_detail.length
  end

  test "progress_percent only exists when the total is known" do
    @run.progress!(bytes: 25)
    assert_nil @run.progress_percent

    @run.progress!(bytes: 25, total_bytes: 100)
    assert_equal 25, @run.progress_percent

    @run.progress!(bytes: 300)
    assert_equal 100, @run.progress_percent
  end
end
