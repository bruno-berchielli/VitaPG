require "test_helper"

class JoinRequestsTest < ActionDispatch::IntegrationTest
  UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36".freeze

  setup do
    @headers = { "HTTP_USER_AGENT" => UA }
    @workspace = workspaces(:acme)
    @outsider = User.create!(name: "Carol", email: "carol@example.com")
  end

  test "an outsider can request to join and an admin can approve" do
    sign_in @outsider
    post workspace_join_request_path(@workspace), headers: @headers
    request = JoinRequest.find_by!(user: @outsider, workspace: @workspace)
    assert request.pending?

    sign_in users(:alice) # owner
    post approve_join_request_path(request), headers: @headers

    assert request.reload.approved?
    assert @workspace.memberships.exists?(user: @outsider)
  end

  test "a plain member cannot decide requests" do
    request = JoinRequest.create!(user: @outsider, workspace: @workspace)

    sign_in users(:bob) # member
    post approve_join_request_path(request), headers: @headers

    assert request.reload.pending?
  end

  test "a superadmin can decide requests anywhere" do
    request = JoinRequest.create!(user: @outsider, workspace: @workspace)

    sign_in users(:root)
    post deny_join_request_path(request), headers: @headers

    assert request.reload.denied?
  end

  test "members cannot request to join again" do
    sign_in users(:bob)
    post workspace_join_request_path(@workspace), headers: @headers

    assert_not JoinRequest.exists?(user: users(:bob), workspace: @workspace)
  end

  test "a superadmin can enter any workspace" do
    sign_in users(:root)
    post switch_workspace_path(@workspace), headers: @headers
    get memberships_path, headers: @headers

    assert_response :success
    assert_match I18n.t("memberships.index.invite.title"), response.body
  end
end
