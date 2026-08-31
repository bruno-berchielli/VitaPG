require "test_helper"

class AdminMembershipsTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  setup do
    @headers = { "HTTP_USER_AGENT" => UA }
  end

  test "a superadmin can edit a user's account" do
    sign_in users(:root)

    patch admin_user_path(users(:bob)), params: { user: { name: "Robert", email: "bob@example.com" } }, headers: @headers

    assert_equal "Robert", users(:bob).reload.name
  end

  test "a superadmin can change a role, add and remove workspaces for a user" do
    sign_in users(:root)
    bob = users(:bob)
    membership = memberships(:bob_acme)

    patch admin_membership_path(membership), params: { membership: { role: "admin" } }, headers: @headers
    assert_equal "admin", membership.reload.role

    other = Workspace.create!(name: "Second WS")
    post admin_user_memberships_path(bob), params: { membership: { workspace_id: other.id, role: "member" } }, headers: @headers
    assert other.memberships.exists?(user: bob)

    delete admin_membership_path(membership), headers: @headers
    assert_not Membership.exists?(membership.id)
  end

  test "the last owner of a workspace cannot be demoted or removed even by a superadmin" do
    sign_in users(:root)
    owner_membership = memberships(:alice_acme)

    patch admin_membership_path(owner_membership), params: { membership: { role: "member" } }, headers: @headers
    assert_equal "owner", owner_membership.reload.role

    delete admin_membership_path(owner_membership), headers: @headers
    assert Membership.exists?(owner_membership.id)
  end

  test "regular users are locked out" do
    sign_in users(:alice)

    patch admin_membership_path(memberships(:bob_acme)), params: { membership: { role: "admin" } }, headers: @headers

    assert_equal "member", memberships(:bob_acme).reload.role
    assert_redirected_to root_path
  end
end
