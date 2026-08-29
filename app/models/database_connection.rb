# == Schema Information
#
# Table name: database_connections
# Database name: primary
#
#  id            :integer          not null, primary key
#  database_name :string
#  host          :string
#  name          :string
#  password      :string
#  port          :integer
#  sslmode       :string
#  username      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  workspace_id  :integer          not null
#
# Indexes
#
#  index_database_connections_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  workspace_id  (workspace_id => workspaces.id)
#
class DatabaseConnection < ApplicationRecord
  belongs_to :workspace
  has_many :backup_routines, dependent: :destroy

  encrypts :password

  validates :name, :host, :port, :username, :password, :database_name, :sslmode, presence: true
  validates :port, numericality: { only_integer: true, in: 1..65_535 }

  enum :sslmode, {
    disable: "disable",
    allow: "allow",
    prefer: "prefer",
    require: "require",
    verify_ca: "verify-ca",
    verify_full: "verify-full"
  }, default: :prefer

  # Everything pg_dump/psql need except the password, which is passed through
  # the spawned process environment only (never argv, never a URL).
  def pg_env
    {
      "PGHOST" => host,
      "PGPORT" => port.to_s,
      "PGUSER" => username,
      "PGPASSWORD" => password,
      "PGDATABASE" => database_name,
      "PGSSLMODE" => sslmode_before_type_cast
    }
  end
end
