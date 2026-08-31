require "test_helper"

class SuperadminBootstrapTest < ActiveSupport::TestCase
  test "the env var accepts a comma-separated list" do
    emails = "first@example.com, second@example.com".split(",").map { |e| e.strip.downcase }
    emails.each do |email|
      user = User.find_or_initialize_by(email: email)
      user.name = email.split("@").first if user.new_record?
      user.superadmin = true
      user.save!
    end

    assert User.find_by(email: "first@example.com").superadmin?
    assert User.find_by(email: "second@example.com").superadmin?
  end
end
