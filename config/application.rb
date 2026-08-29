require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VitaPg
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.available_locales = [ :en, :"pt-BR", :es ]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = [ :en ]
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]
    # ViewComponent sidecar .yml files participate in normal I18n.t lookups.
    config.i18n.load_path += Dir[Rails.root.join("app/components/**/*.yml")]

    config.view_component.generate.sidecar = true
    config.view_component.generate.locale = true
    config.view_component.generate.distinct_locale_files = false
    config.view_component.generate.stimulus_controller = true
  end
end
