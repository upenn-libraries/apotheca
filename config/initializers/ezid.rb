Ezid::Client.configure do |conf|
  conf.default_shoulder = 'ark:/99999/fk4'
  conf.user = 'apitest'
  conf.password = 'apitest'
  conf.retry_interval = Rails.env.test? ? 0 : 5
  conf.logger = Logger.new(File::NULL) if Rails.env.test?
end
