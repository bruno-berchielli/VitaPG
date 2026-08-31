require "application_system_test_case"

class CoreFlowsTest < ApplicationSystemTestCase
  setup do
    @user = users(:alice)
  end

  def sign_in
    login_as @user, scope: :user
    visit root_path
    assert_text I18n.t("dashboard.show.title")
  end

  test "the dashboard renders for a signed-in user" do
    sign_in

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

  test "ssh fields appear only when the connection mode is a tunnel" do
    sign_in
    visit new_database_connection_path

    assert_no_selector "input[name='database_connection[ssh_host]']", visible: :visible
    select I18n.t("database_connections.form.modes.ssh_tunnel"), from: "database_connection[connection_mode]"
    assert_selector "input[name='database_connection[ssh_host]']", visible: :visible
    select I18n.t("database_connections.form.modes.direct"), from: "database_connection[connection_mode]"
    assert_no_selector "input[name='database_connection[ssh_host]']", visible: :visible
  end

  test "custom cron field appears when choosing the custom frequency" do
    sign_in
    visit new_backup_routine_path

    assert_no_selector "input[name='backup_routine[cron]']", visible: :visible
    select I18n.t("backup_routines.form.custom_frequency"), from: "cron_preset"
    assert_selector "input[name='backup_routine[cron]']", visible: :visible
  end

  test "creating a backup routine through the form" do
    sign_in
    visit new_backup_routine_path

    fill_in "backup_routine[name]", with: "Weekly staging"
    select database_connections(:prod).name, from: "backup_routine[database_connection_id]"
    select destinations(:minio).name, from: "backup_routine[destination_id]"
    select I18n.t("cron.weekly", day: "Sunday", time: "03:00"), from: "cron_preset"
    fill_in "backup_routine[retention_keep_last]", with: "5"
    click_on I18n.t("actions.save")

    assert_text I18n.t("backup_routines.create.created")
    assert_text I18n.t("cron.weekly", day: "Sunday", time: "03:00")
  end
end
