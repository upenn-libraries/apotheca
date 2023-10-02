# frozen_string_literal: true
Rails.application.config.to_prepare do
  unless Rails.env.test?
    redis_connection = {
      url: ENV.fetch('REDIS_URL', 'localhost:6379'),
      username: ENV.fetch('REDIS_SIDEKIQ_USER', 'sidekiq'),
      password: DockerSecrets.lookup(:redis_sidekiq_password)
    }

    Sidekiq.default_job_options = { retry: 3, backtrace: 5 }

    Sidekiq.configure_server do |config|
      config.redis = redis_connection
      config.error_handlers << proc { |e, context| Honeybadger.notify(e, context: context) }
    end

    Sidekiq.configure_client do |config|
      config.redis = redis_connection
    end
  end
end

