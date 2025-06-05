# == Schema Information
#
# Table name: destinations
#
#  id                :integer          not null, primary key
#  bucket            :string
#  credentials_path  :string
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
end
