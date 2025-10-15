# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
require 'action_view/railtie'
# require 'action_cable/engine'
# require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Apotheca
  # Application configuration
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks core_extensions])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.time_zone = 'Eastern Time (US & Canada)'

    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Rails 7 raises an exception on attempts to redirect to an external URL, but
    # we need this to redirect to IdP logout page after Devise logout
    # Alternative would be to monkeypatch Devise::SessionsController#respond_to_on_destroy
    # Devise Issue: https://github.com/heartcombo/devise/pull/5462
    # Rails Issue: https://github.com/rails/rails/issues/39643
    # Related CVE: https://discuss.rubyonrails.org/t/cve-2023-22797-possible-open-redirect-vulnerability-in-action-pack/82120
    config.action_controller.raise_on_open_redirects = false
  end
end
