# == Schema Information
#
# Table name: backup_routines
#
#  id                     :integer          not null, primary key
#  frequency              :string
#  name                   :string
#  no_owner               :boolean          default(FALSE), not null
#  no_privileges          :boolean          default(FALSE), not null
#  tables_to_exclude      :text
#  tables_to_exclude_data :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  database_connection_id :integer          not null
#  destination_id         :integer          not null
#
# Indexes
#
#  index_backup_routines_on_database_connection_id  (database_connection_id)
#  index_backup_routines_on_destination_id          (destination_id)
#
# Foreign Keys
#
#  database_connection_id  (database_connection_id => database_connections.id)
#  destination_id          (destination_id => destinations.id)
#
class BackupRoutine < ApplicationRecord
  belongs_to :database_connection
  belongs_to :destination

  has_many :backup_runs, dependent: :destroy

  enum :frequency, {
    daily: "daily",
    hourly: "hourly",
    weekly: "weekly"
  }

  serialize :tables_to_exclude, coder: JSON, type: Array
  serialize :tables_to_exclude_data, coder: JSON, type: Array

  validates :name, :frequency, presence: true
end
