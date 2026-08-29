# Zero-touch first account for fresh installs: set VITAPG_SUPERADMIN_EMAIL and
# the user exists after boot, ready to sign in with a magic link (or Google).
# Also available on demand via `bin/rails vitapg:superadmin EMAIL=...`.
Rails.application.config.after_initialize do
  email = ENV["VITAPG_SUPERADMIN_EMAIL"].to_s.strip.downcase
  next if email.blank?

  begin
    user = User.find_or_initialize_by(email: email)
    user.name = ENV["VITAPG_SUPERADMIN_NAME"].presence || email.split("@").first if user.new_record?
    user.superadmin = true
    user.save! if user.changed?
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid
    # Database not created/migrated yet (assets:precompile, db:prepare boot).
  end
end
