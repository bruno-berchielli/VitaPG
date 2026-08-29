require "test_helper"

class RegistrationsClosedTest < ActionDispatch::IntegrationTest
  test "signup is closed once a user exists" do
    get new_user_registration_path

    assert_redirected_to new_user_session_path
  end

  test "signup is open on a fresh instance" do
    Membership.delete_all
    User.delete_all

    get new_user_registration_path

    assert_response :success
  end
end
