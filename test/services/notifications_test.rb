require "test_helper"

class NotificationsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @routine = backup_routines(:nightly)
  end

  def create_run(status:, size: 1000)
    @routine.runs.create!(status: status, size_bytes: size, started_at: 1.minute.ago, finished_at: Time.current,
                          file_key: status == :failed ? nil : "a/x.dump")
  end

  test "dispatcher enqueues one job per matching channel" do
    run = create_run(status: :failed)

    assert_enqueued_jobs 2, only: NotifyRunJob do
      Notifications::Dispatcher.call(run)
    end
  end

  test "dispatcher skips channels that do not match the event" do
    run = create_run(status: :completed)

    # Only the webhook channel has notify_on_success
    assert_enqueued_jobs 1, only: NotifyRunJob do
      Notifications::Dispatcher.call(run)
    end
  end

  test "dispatcher skips disabled channels" do
    notification_channels(:hook).update!(enabled: false)
    run = create_run(status: :completed)

    assert_enqueued_jobs 0, only: NotifyRunJob do
      Notifications::Dispatcher.call(run)
    end
  end

  test "webhook notifier signs the payload" do
    run = create_run(status: :completed)
    channel = notification_channels(:hook)
    captured = {}

    notifier = Notifications::WebhookNotifier.new(channel, run)
    notifier.define_singleton_method(:post_json!) do |url, body, headers|
      captured.merge!(url: url, body: body, headers: headers)
    end
    notifier.call

    assert_equal "https://hooks.example.com/vitapg", captured[:url]

    payload = JSON.parse(captured[:body])
    assert_equal "backup.completed", payload["event"]
    assert_equal @routine.name, payload.dig("routine", "name")

    signature = captured[:headers]["X-Vitapg-Signature"]
    timestamp = signature[/t=(\d+)/, 1]
    expected = OpenSSL::HMAC.hexdigest("SHA256", "sekret", "#{timestamp}.#{captured[:body]}")
    assert_equal expected, signature[/v1=(\h+)/, 1]
  end

  test "webhook channels get a generated signing secret" do
    channel = workspaces(:acme).notification_channels.create!(name: "x", kind: "webhook", url: "https://example.com/h")

    assert channel.signing_secret.present?
  end
end
