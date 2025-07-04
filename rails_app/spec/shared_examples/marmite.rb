# frozen_string_literal: true

# Shared context that provides mocked Marmite requests.

# Stub request for successful Marmite request.
shared_context 'with successful Marmite request' do
  let(:bibnumber) { MMSIDValidator::EXAMPLE_VALID_MMS_ID }

  before do
    stub_request(:get, "#{Settings.marmite.url}/api/v2/records/#{bibnumber}/marc21?update=always")
      .to_return(status: 200, body: xml, headers: {})
  end
end

# Stub request for unsuccessful Marmite request.
shared_context 'with unsuccessful Marmite request' do
  let(:bibnumber) { MMSIDValidator::EXAMPLE_VALID_MMS_ID }

  before do
    stub_request(:get, "#{Settings.marmite.url}/api/v2/records/#{bibnumber}/marc21?update=always")
      .to_return(status: 500, body: '<html><head></head><body>Internal Server Error</body></html>', headers: {})
  end
end
