# frozen_string_literal: true

# Shared context that provides mocked EZID web requests.
shared_context 'with successful EZID responses' do
  before do
    # Stub request to mint ezids
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

    # Stub request to update ezids
    stub_request(:post, %r{#{Ezid::Client.config.host}/id/.*})
      .with(
        basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
        headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
      )
      .to_return { |request|
        {
          status: 200,
          headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
          body: "success: #{request.uri.path.split('/', 3).last}"
        }
      }
  end
end
