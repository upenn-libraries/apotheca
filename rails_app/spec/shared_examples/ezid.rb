# frozen_string_literal: true

# Shared context that provides mocked EZID web requests.

# Shared contexts that provide successful EZID responses.

# Stub request to successfully mint ezids.
shared_context 'with successful requests to mint EZID' do
  before do
    stub_request(:post, "https://#{Ezid::Client.config.host}/shoulder/#{Ezid::Client.config.default_shoulder}")
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return(
        status: 201,
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
        body: "success: #{Ezid::Client.config.default_shoulder}#{SecureRandom.hex(4)}"
      )
  end
end

# Stub request to update ezids
shared_context 'with successful requests to update EZID' do
  before do
    stub_request(:post, %r{#{Ezid::Client.config.host}/id/.*})
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return do |request|
        {
          status: 200,
          headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
          body: "success: #{request.uri.path.split('/', 3).last}"
        }
      end
  end
end

shared_context 'with successful requests to lookup EZID' do
  before do
    stub_request(:get, %r{#{Ezid::Client.config.host}/id/.*})
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return do |request|
        {
          status: 200,
          headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
          body: "success: #{request.uri.path.split('/', 3).last}"
        }
      end
  end
end

# Shared contexts that provide unsuccessful EZID responses.
# EZID documentation about error reporting: https://ezid.cdlib.org/doc/apidoc.html#error-reporting

# Stub unsuccessful request to get EZID
shared_context 'with unsuccessful requests to lookup EZID' do
  before do
    stub_request(:get, %r{#{Ezid::Client.config.host}/id/.*})
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return(
        status: 400,
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
        body: 'error: bad request - no such identifier'
      )
  end
end

shared_context 'with unsuccessful requests to mint EZID' do
  before do
    stub_request(:post, "https://#{Ezid::Client.config.host}/shoulder/#{Ezid::Client.config.default_shoulder}")
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return(
        status: 400,
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
        body: 'error: bad request' # Fake error message
      )
  end
end

shared_context 'with unsuccessful requests to update EZID' do
  before do
    stub_request(:post, %r{#{Ezid::Client.config.host}/id/.*})
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return(
        status: 404,
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
        body: 'error: no such identifier' # Fake error message
      )
  end
end
