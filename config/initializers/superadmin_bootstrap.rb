# Zero-touch first accounts for fresh installs: VITAPG_SUPERADMIN_EMAIL takes
# one or more comma-separated emails; each exists as a superadmin after boot,
# ready to sign in with a magic link (or Google). Also available on demand via
# `bin/rails vitapg:superadmin EMAIL=...`.
Rails.application.config.after_initialize do
  emails = ENV["VITAPG_SUPERADMIN_EMAIL"].to_s.split(",").map { |e| e.strip.downcase }.reject(&:empty?)
  next if emails.empty?

  begin
    emails.each do |email|
      user = User.find_or_initialize_by(email: email)
      user.name = email.split("@").first if user.new_record?
      user.name = ENV["VITAPG_SUPERADMIN_NAME"].presence || user.name if emails.one? && user.new_record?
      user.superadmin = true
      user.save! if user.changed?
    end
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    # Database not created/migrated yet (assets:precompile, db:prepare boot).
  end
end
