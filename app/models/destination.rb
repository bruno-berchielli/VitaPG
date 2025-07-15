# == Schema Information
#
# Table name: destinations
#
#  id                :integer          not null, primary key
#  access_token      :string
#  bucket            :string
#  client_secret     :string
#  credentials_path  :string
#  expires_at        :datetime
#  name              :string
#  provider          :string
#  refresh_token     :string
#  region            :string
#  secret_access_key :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  access_key_id     :string
#  client_id         :string
#  folder_id         :string
#  project_id        :string
#

class Destination < ApplicationRecord
  enum :provider, { s3: "s3", google_drive: "google_drive" }

  has_many :backup_routines, dependent: :nullify

  validates :name, :provider, presence: true
end
