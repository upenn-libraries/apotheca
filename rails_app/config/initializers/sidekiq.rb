# frozen_string_literal: true

Rails.application.config.to_prepare do
  unless Rails.env.test?
    redis_connection = {
      url: Settings.redis.url,
      username: Settings.redis.username,
      password: Settings.redis.password
    }

    Sidekiq.default_job_options = { backtrace: 5 }

    Sidekiq.configure_server do |config|
      config.redis = redis_connection
      config.error_handlers << proc { |e, context| Honeybadger.notify(e, context: context) }
      config.super_fetch!
      config.reliable_scheduler!
    end

    Sidekiq::Client.reliable_push!

    Sidekiq.configure_client do |config|
      config.redis = redis_connection
    end
  end
end
