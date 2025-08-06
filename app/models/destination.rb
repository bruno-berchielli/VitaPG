# == Schema Information
#
# Table name: destinations
#
#  id                :integer          not null, primary key
#  bucket            :string
#  credentials_path  :string
#  endpoint          :string
#  name              :string
#  provider          :string
#  region            :string
#  secret_access_key :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  access_key_id     :string
#  project_id        :string
#
class Destination < ApplicationRecord
  enum :provider, { s3: "s3", google_drive: "google_drive" }

  has_many :backup_routines, dependent: :nullify

  validates :name, :provider, :bucket, presence: true
end
