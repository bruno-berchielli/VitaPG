require "test_helper"

class AdminUsersTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  setup do
    @headers = { "HTTP_USER_AGENT" => UA }
  end

  test "regular users cannot open instance administration" do
    sign_in users(:alice)
    get admin_users_path, headers: @headers

    assert_redirected_to root_path
  end

  test "a superadmin can create another superadmin" do
    sign_in users(:root)

    assert_enqueued_emails 1 do
      post admin_users_path, params: { user: { email: "second@example.com", name: "Second", superadmin: "1" } }, headers: @headers
    end

    created = User.find_by(email: "second@example.com")
    assert created.superadmin?
  end

  test "a superadmin can promote and demote an existing user" do
    sign_in users(:root)

    patch toggle_superadmin_admin_user_path(users(:alice)), headers: @headers
    assert users(:alice).reload.superadmin?

    patch toggle_superadmin_admin_user_path(users(:alice)), headers: @headers
    assert_not users(:alice).reload.superadmin?
  end

  test "a superadmin cannot change their own flag" do
    sign_in users(:root)

    patch toggle_superadmin_admin_user_path(users(:root)), headers: @headers

    assert users(:root).reload.superadmin?
  end

  test "a regular user cannot toggle anyone" do
    sign_in users(:alice)

    patch toggle_superadmin_admin_user_path(users(:root)), headers: @headers

    assert users(:root).reload.superadmin?
    assert_redirected_to root_path
  end
end
