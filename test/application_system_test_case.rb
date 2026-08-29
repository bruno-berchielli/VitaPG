require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Warden::Test::Helpers
  # Pin the browser locale so assertions match I18n defaults regardless of the
  # machine's system language.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_preference("intl.accept_languages", "en-US")
  end
end
