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
#  sslmode       :string
#  username      :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class DatabaseConnection < ApplicationRecord
end
