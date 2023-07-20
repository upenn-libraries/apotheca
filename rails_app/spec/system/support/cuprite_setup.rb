# frozen_string_literal: true

# Cuprite config based on https://evilmartians.com/chronicles/system-of-a-test-setting-up-end-to-end-rails-testing

# First, load Cuprite Capybara integration
require 'capybara/cuprite'

# Parse URL
# NOTE: REMOTE_CHROME_HOST should be added to Webmock/VCR allowlist if you use any of those.
REMOTE_CHROME_URL = ENV.fetch('CHROME_URL', nil)
REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
  if REMOTE_CHROME_URL
    URI.parse(REMOTE_CHROME_URL).then do |uri|
      [uri.host, uri.port]
    end
  end

# Check whether the remote chrome is running.
remote_chrome =
  begin
    if REMOTE_CHROME_URL.nil?
      false
    else
      Socket.tcp(REMOTE_CHROME_HOST, REMOTE_CHROME_PORT, connect_timeout: 1).close
      true
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
    false
  end

remote_options = remote_chrome ? { url: REMOTE_CHROME_URL } : {}

# Then, we need to register our driver to be able to use it later
# with #driven_by method.
# NOTE: The name :cuprite is already registered by Rails.
# See https://github.com/rubycdp/cuprite/issues/180
Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    **{
      window_size: [1200, 800],
      # smooth scrolling for ARM systems moves too slow causing elements to remain outside of viewport during testing
      # resulting in failing tests
      # See: https://codemeister.dev/capybara-cuprite-and-a-slow-scrolling-chrome-arm
      browser_options: if remote_chrome
                         { 'no-sandbox' => nil, 'disable-smooth-scrolling' => true }
                       else
                         { 'disable-smooth-scrolling' => true }
                       end,
      # Increase Chrome startup wait time (required for stable CI builds)
      process_timeout: 10,
      # Enable debugging capabilities
      inspector: true,
      js_errors: true,
      timeout: 10
    }.merge(remote_options)
  )
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite
