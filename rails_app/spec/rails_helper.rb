# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'valkyrie/specs/shared_specs'
require 'aasm/rspec'
require 'simplecov'
SimpleCov.start 'rails' do
  enable_coverage :branch
end
require 'webmock/rspec'
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    Settings.minio.endpoint,
    /#{Settings.solr.url}/,
    /#{Settings.fits.url}/,
    /#{ENV.fetch('CHROME_URL', 'http://chrome:3000')}/
  ]
)

# Explicitly requiring sidekiq testing.
require 'sidekiq/testing'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/{support,shared_examples}/**/*.rb')].each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers

  # RSpec Devise helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Adding Valkyrie persist strategy for FactoryBot
  FactoryBot.register_strategy(:persist, ValkyriePersistStrategy)

  # Skipping tests that do not run properly on ARM Architectures.
  config.filter_run_excluding(:skip_on_arm) if /^(arm64|aarch64)/.match?(RUBY_PLATFORM)

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.file_fixture_path = 'spec/fixtures'

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  # Perform cleanup tasks before each test.
  config.before do
    cleanup_tasks
  end

  config.before(:suite) do
    TestWorkingStorage.load_example_files
  end

  # Perform cleanup tasks at the end of suite in order to clean up after the last test.
  config.after(:suite) do
    cleanup_tasks
    clear_active_storage_files
    TestWorkingStorage.clean
  end

  # Combine cleanup tasks
  def cleanup_tasks
    wipe_metadata_adapters!
    wipe_storage_adapters!
    clear_enqueued_jobs
    clear_performed_jobs
  end

  # Clean out all Valkyrie Storage adapters.
  def wipe_storage_adapters!
    Valkyrie::StorageAdapter.storage_adapters.each do |_short_name, adapter|
      adapter.shrine.clear! if adapter.is_a? Valkyrie::Storage::Shrine
    end
  end

  # Clean out Valkyrie Metadata Adapters.
  def wipe_metadata_adapters!
    Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister.wipe!
  end

  # Clear enqueued jobs
  def clear_enqueued_jobs
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  # Clear performed jobs
  def clear_performed_jobs
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end

  # Clear ActiveStorage files generated during tests
  def clear_active_storage_files
    FileUtils.rm_rf(ActiveStorage::Blob.services.fetch(:test).root)
  end
end
