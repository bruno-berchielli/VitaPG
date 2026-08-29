require "test_helper"

class MembershipsControllerTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  # Regression: the invite form uses form_with without a model (object = false),
  # which must not break the custom form builder.
  test "index renders the invite form for managers" do
    post user_session_path, params: { user: { email: "alice@example.com", password: "password123" } },
                            headers: { "HTTP_USER_AGENT" => UA }
    get memberships_path, headers: { "HTTP_USER_AGENT" => UA }

    assert_response :success
    assert_match I18n.t("memberships.index.invite.title"), response.body
  end
end
