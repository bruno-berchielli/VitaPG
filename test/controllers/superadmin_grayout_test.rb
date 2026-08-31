require "test_helper"

class SuperadminGrayoutTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  test "the admin edit page disables workspace roles for superadmins" do
    users(:bob).update!(superadmin: true)
    sign_in users(:root)

    get edit_admin_user_path(users(:bob)), headers: { "HTTP_USER_AGENT" => UA }

    assert_response :success
    assert_match I18n.t("admin.users.edit.workspaces.global_access"), response.body
    assert_match "pointer-events-none", response.body
  end

  test "the members page shows a chip instead of a role select for superadmins" do
    users(:bob).update!(superadmin: true)
    sign_in users(:alice)

    get memberships_path, headers: { "HTTP_USER_AGENT" => UA }

    assert_match I18n.t("memberships.index.superadmin_tip"), response.body
  end
end
