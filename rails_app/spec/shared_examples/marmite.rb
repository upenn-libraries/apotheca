# frozen_string_literal: true

# Shared context that provides mocked Marmite requests.

# Stub request for successful Marmite request.
shared_context 'with successful Marmite request' do
  let(:bibnumber) { 'sample-bib' }

  before do
    stub_request(:get, "#{Settings.marmite.url}/api/v2/records/#{bibnumber}/marc21?update=always")
      .to_return(status: 200, body: xml, headers: {})
  end
end
