require "test_helper"

class NotificationChannelsControllerTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  test "a superadmin outside the workspace is offered to add a channel" do
    sign_in users(:root)

    get notification_channels_path, headers: { "HTTP_USER_AGENT" => UA }

    assert_response :success
    assert_match new_notification_channel_path, response.body
  end

  test "a plain member is not offered to add a channel" do
    sign_in users(:bob)

    get notification_channels_path, headers: { "HTTP_USER_AGENT" => UA }

    assert_response :success
    assert_no_match new_notification_channel_path, response.body
  end
end
