class AddProgressToBackupRuns < ActiveRecord::Migration[8.1]
  def change
    change_table :backup_runs, bulk: true do |t|
      t.datetime :stage_started_at
      t.bigint :progress_bytes
      t.bigint :progress_rate_bps
      t.bigint :progress_total_bytes
      t.string :progress_detail
      t.bigint :source_size_bytes
    end
  end
end
