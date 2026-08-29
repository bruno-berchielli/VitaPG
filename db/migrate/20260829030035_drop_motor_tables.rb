class DropMotorTables < ActiveRecord::Migration[8.1]
  # The Motor-Admin UI was replaced by the application's own interface.
  # Irreversible: these tables belonged to the removed gem.
  def up
    %i[
      motor_alert_locks motor_alerts motor_api_configs motor_audits
      motor_configs motor_dashboards motor_forms motor_note_tag_tags
      motor_note_tags motor_notes motor_notifications motor_queries
      motor_reminders motor_resources motor_taggable_tags motor_tags
    ].each do |table|
      drop_table table, if_exists: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
