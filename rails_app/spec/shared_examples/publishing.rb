# frozen_string_literal: true

# Shared contexts that provides mocked publishing web requests.

# Shared context that provides successful publish request.
shared_context 'with successful publish request' do
  let(:publishing_endpoint) { PublishingService::Endpoint.digital_collections }

  before do
    stub_request(:post, publishing_endpoint.webhook_url)
      .with(
        body: be_a(String),
        headers: { 'Content-Type': 'application/json',
                   'Authorization': "Token token=#{publishing_endpoint.token}" }
      )
      .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
  end
end

# Shared context that provides unsuccessful publish request.
shared_context 'with unsuccessful publish request' do
  let(:publishing_endpoint) { PublishingService::Endpoint.digital_collections }

  before do
    stub_request(:post, publishing_endpoint.webhook_url)
      .with(
        body: be_a(String),
        headers: { 'Content-Type': 'application/json',
                   'Authorization': "Token token=#{publishing_endpoint.token}" }
      )
      .to_return(
        status: 500,
        body: { error: 'Crazy Solr error' }.to_json,
        headers: { 'Content-Type': 'application/json' }
      )
  end
end

shared_context 'with successful unpublish request' do
  let(:publishing_endpoint) { PublishingService::Endpoint.digital_collections }

  before do
    raise 'item must be set with `let(:item)`' unless defined? item

    stub_request(:post, publishing_endpoint.webhook_url)
      .with(
        body: { event: 'unpublish', data: { item: { id: item.id } } },
        headers: { 'Authorization': "Token token=#{publishing_endpoint.token}" }
      )
      .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
  end
end

shared_context 'with unsuccessful unpublish request' do
  let(:publishing_endpoint) { PublishingService::Endpoint.digital_collections }

  before do
    raise 'item must be set with `let(:item)`' unless defined? item

    stub_request(:post, publishing_endpoint.webhook_url)
      .with(
        body: { event: 'unpublish', data: { item: { id: item.id } } },
        headers: { 'Authorization': "Token token=#{publishing_endpoint.token}" }
      )
      .to_return(
        status: 500, body: { error: 'Crazy Solr error' }.to_json, headers: { 'Content-Type': 'application/json' }
      )
  end
end
