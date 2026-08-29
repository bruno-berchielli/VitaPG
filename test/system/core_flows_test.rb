require "application_system_test_case"

class CoreFlowsTest < ApplicationSystemTestCase
  setup do
    @user = users(:alice)
  end

  def sign_in
    visit new_user_session_path
    fill_in "user[email]", with: @user.email
    fill_in "user[password]", with: "password123"
    click_on I18n.t("devise.sessions.new.sign_in")
    assert_text I18n.t("dashboard.show.title")
  end

  test "signing in lands on the dashboard" do
    sign_in

    assert_text I18n.t("dashboard.show.title")
    assert_text "Acme"
  end

  test "creating a database connection through the form" do
    sign_in
    visit new_database_connection_path

    fill_in "database_connection[name]", with: "Staging"
    fill_in "database_connection[host]", with: "db.internal"
    fill_in "database_connection[port]", with: "5432"
    fill_in "database_connection[database_name]", with: "staging_db"
    fill_in "database_connection[username]", with: "reader"
    fill_in "database_connection[password]", with: "secret123"
    click_on I18n.t("actions.save")

    assert_text I18n.t("database_connections.create.created")
    assert_text "db.internal:5432"
  end

  test "creating a backup routine through the form" do
    sign_in
    visit new_backup_routine_path

    fill_in "backup_routine[name]", with: "Weekly staging"
    select database_connections(:prod).name, from: "backup_routine[database_connection_id]"
    select destinations(:minio).name, from: "backup_routine[destination_id]"
    fill_in "backup_routine[cron]", with: "0 4 * * 0"
    fill_in "backup_routine[retention_keep_last]", with: "5"
    click_on I18n.t("actions.save")

    assert_text I18n.t("backup_routines.create.created")
    assert_text "0 4 * * 0"
  end
end
