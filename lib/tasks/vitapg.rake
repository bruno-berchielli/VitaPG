namespace :vitapg do
  desc "Create or promote a superadmin (EMAIL=..., optional NAME=...)"
  task superadmin: :environment do
    email = ENV.fetch("EMAIL").strip.downcase
    user = User.find_or_initialize_by(email: email)
    user.name = ENV["NAME"].presence || user.name.presence || email.split("@").first
    user.superadmin = true
    user.save!
    puts "#{user.email} is a superadmin. They can now sign in with a magic link."
  end
end
