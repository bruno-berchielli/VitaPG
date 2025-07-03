# == Schema Information
#
# Table name: database_connections
#
#  id            :integer          not null, primary key
#  database_name :string
#  host          :string
#  name          :string
#  password      :string
#  port          :integer
#  username      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class DatabaseConnection < ApplicationRecord
  has_many :backup_routines, dependent: :destroy

  validates :name, :host, :port, :username, :password, :database_name, :sslmode, presence: true

  enum :sslmode, { disable: "disable", allow: "allow" , prefer: "prefer", require: "require", verify_ca: "verify-ca", verify_full: "verify-full" }, default: :disable

  def connection_url
    "postgres://#{username}:#{password}@#{host}:#{port}/#{database_name}?sslmode=#{sslmode}"
  end
end
