# frozen_string_literal: true

Ezid::Client.configure do |conf|
  conf.default_shoulder = Settings.ezid.default_shoulder
  conf.user = Settings.ezid.user
  conf.password = Settings.ezid.password
  conf.retry_interval = Rails.env.test? ? 0 : 5
  conf.logger = Logger.new(File::NULL) if Rails.env.test?
end
