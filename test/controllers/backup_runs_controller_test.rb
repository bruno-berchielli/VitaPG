require "test_helper"

class BackupRunsControllerTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  setup do
    sign_in users(:bob)
    @run = backup_routines(:nightly).runs.create!(status: :dumping, trigger: :manual, started_at: Time.current)
  end

  test "a member can request to cancel a running backup" do
    post cancel_backup_run_path(@run), headers: { "HTTP_USER_AGENT" => UA }

    assert_redirected_to backup_run_path(@run)
    assert_equal I18n.t("backup_runs.cancel.requested"), flash[:notice]
    assert @run.reload.cancel_requested?
    assert @run.dumping?
  end

  test "a finished run cannot be canceled" do
    @run.update!(status: :completed, finished_at: Time.current)

    post cancel_backup_run_path(@run), headers: { "HTTP_USER_AGENT" => UA }

    assert_equal I18n.t("backup_runs.cancel.not_running"), flash[:alert]
    assert_not @run.reload.cancel_requested?
  end

  test "the run page offers cancel while in progress" do
    get backup_run_path(@run), headers: { "HTTP_USER_AGENT" => UA }

    assert_response :success
    assert_match cancel_backup_run_path(@run), response.body
  end
end
