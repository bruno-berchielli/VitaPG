# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_31_135327) do
  create_table "backup_logs", force: :cascade do |t|
    t.integer "backup_run_id", null: false
    t.datetime "created_at", null: false
    t.json "message"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["backup_run_id"], name: "index_backup_logs_on_backup_run_id"
  end

  create_table "backup_routines", force: :cascade do |t|
    t.integer "compression_level", default: 6, null: false
    t.datetime "created_at", null: false
    t.string "cron", default: "0 0 * * *", null: false
    t.integer "database_connection_id", null: false
    t.integer "destination_id", null: false
    t.boolean "enabled", default: true, null: false
    t.string "format", default: "custom", null: false
    t.datetime "last_missed_alert_at"
    t.string "name"
    t.boolean "no_owner", default: false, null: false
    t.boolean "no_privileges", default: false, null: false
    t.integer "parallel_jobs", default: 1, null: false
    t.string "path_prefix"
    t.integer "retention_keep_last"
    t.integer "retention_max_age_days"
    t.string "schedule_timezone", default: "UTC", null: false
    t.text "tables_to_exclude"
    t.text "tables_to_exclude_data"
    t.datetime "updated_at", null: false
    t.integer "workspace_id", null: false
    t.index ["database_connection_id"], name: "index_backup_routines_on_database_connection_id"
    t.index ["destination_id"], name: "index_backup_routines_on_destination_id"
    t.index ["workspace_id"], name: "index_backup_routines_on_workspace_id"
  end

  create_table "backup_runs", force: :cascade do |t|
    t.integer "backup_routine_id", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "file_key"
    t.datetime "finished_at"
    t.bigint "size_bytes"
    t.datetime "started_at"
    t.string "status"
    t.string "trigger", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.index ["backup_routine_id"], name: "index_backup_runs_on_backup_routine_id"
  end

  create_table "database_connections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "database_name"
    t.string "host"
    t.string "name"
    t.string "password"
    t.integer "port"
    t.string "sslmode"
    t.datetime "updated_at", null: false
    t.string "username"
    t.integer "workspace_id", null: false
    t.index ["workspace_id"], name: "index_database_connections_on_workspace_id"
  end

  create_table "destinations", force: :cascade do |t|
    t.string "access_key_id"
    t.string "bucket"
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "name"
    t.string "provider"
    t.string "region"
    t.string "secret_access_key"
    t.datetime "updated_at", null: false
    t.integer "workspace_id", null: false
    t.index ["workspace_id"], name: "index_destinations_on_workspace_id"
  end

  create_table "join_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.integer "decided_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "workspace_id", null: false
    t.index ["decided_by_id"], name: "index_join_requests_on_decided_by_id"
    t.index ["user_id", "workspace_id"], name: "index_join_requests_on_user_id_and_workspace_id", unique: true
    t.index ["user_id"], name: "index_join_requests_on_user_id"
    t.index ["workspace_id"], name: "index_join_requests_on_workspace_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "workspace_id", null: false
    t.index ["user_id", "workspace_id"], name: "index_memberships_on_user_id_and_workspace_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.index ["workspace_id"], name: "index_memberships_on_workspace_id"
  end

  create_table "notification_channels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.boolean "notify_on_failure", default: true, null: false
    t.boolean "notify_on_success", default: false, null: false
    t.string "recipients"
    t.string "signing_secret"
    t.datetime "updated_at", null: false
    t.string "url"
    t.integer "workspace_id", null: false
    t.index ["workspace_id"], name: "index_notification_channels_on_workspace_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name", default: "", null: false
    t.json "preferences", default: {}, null: false
    t.datetime "remember_created_at"
    t.string "remember_token"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "backup_logs", "backup_runs"
  add_foreign_key "backup_routines", "database_connections"
  add_foreign_key "backup_routines", "destinations"
  add_foreign_key "backup_routines", "workspaces"
  add_foreign_key "backup_runs", "backup_routines"
  add_foreign_key "database_connections", "workspaces"
  add_foreign_key "destinations", "workspaces"
  add_foreign_key "join_requests", "users"
  add_foreign_key "join_requests", "users", column: "decided_by_id"
  add_foreign_key "join_requests", "workspaces"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "workspaces"
  add_foreign_key "notification_channels", "workspaces"
end
