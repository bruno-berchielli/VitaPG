source "https://rubygems.org"

ruby "4.0.1"

gem "rails", "~> 8.1"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 6.6.0"
gem "jsbundling-rails"
gem "cssbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "view_component"
gem "jbuilder"
gem "bcrypt", "~> 3.1.7"
gem "devise"
gem "pagy"
gem "fugit"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "mission_control-jobs"
gem "aws-sdk-s3"

group :development, :test do
  gem "annotaterb"
  gem "dotenv"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "foreman"
  gem "rubocop-rails-omakase", require: false
  gem "brakeman", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

gem "devise-i18n", "~> 1.16"
