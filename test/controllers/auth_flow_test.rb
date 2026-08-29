require "test_helper"

class AuthFlowTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  setup do
    @headers = { "HTTP_USER_AGENT" => UA }
  end

  test "requesting a magic link enqueues the email for a known address" do
    assert_enqueued_emails 1 do
      post user_session_path, params: { email: users(:alice).email }, headers: @headers
    end
    assert_redirected_to new_user_session_path
  end

  test "unknown emails get the same response and no email" do
    assert_enqueued_emails 0 do
      post user_session_path, params: { email: "nobody@example.com" }, headers: @headers
    end
    assert_redirected_to new_user_session_path
  end

  test "a valid magic link signs the user in" do
    token = users(:alice).generate_token_for(:magic_login)

    get verify_user_session_path(token: token), headers: @headers
    assert_redirected_to root_path

    get root_path, headers: @headers
    assert_response :success
  end

  test "a bad token does not sign anyone in" do
    get verify_user_session_path(token: "garbage"), headers: @headers
    assert_redirected_to new_user_session_path

    get root_path, headers: @headers
    assert_redirected_to new_user_session_path
  end

  test "there is no registration route" do
    get "/users/sign_up"
    assert_response :not_found
  rescue ActionController::RoutingError
    assert true
  end
end
