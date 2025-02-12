# frozen_string_literal: true

# Shared contexts that provides mocked publishing web requests.

# Shared context that provides successful publish request.
shared_context 'with successful publish request' do
  before do
    stub_request(:post, "#{Settings.publish.colenda.base_url}/items")
      .with(
        body: be_a(String),
        headers: { 'Content-Type': 'application/json', 'Authorization': "Token token=#{Settings.publish.colenda.token}" }
      )
      .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
  end
end

# Shared context that provides unsuccessful publish request.
shared_context 'with unsuccessful publish request' do
  before do
    stub_request(:post, "#{Settings.publish.colenda.base_url}/items")
      .with(
        body: be_a(String),
        headers: { 'Content-Type': 'application/json', 'Authorization': "Token token=#{Settings.publish.colenda.token}" }
      )
      .to_return(
        status: 500,
        body: { error: 'Crazy Solr error' }.to_json,
        headers: { 'Content-Type': 'application/json' }
      )
  end
end

shared_context 'with successful unpublish request' do
  before do
    raise 'item must be set with `let(:item)`' unless defined? item

    stub_request(:delete, "#{Settings.publish.colenda.base_url}/items/#{item.unique_identifier}")
      .with(
        headers: { 'Authorization': "Token token=#{Settings.publish.colenda.token}" }
      )
      .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
  end
end

shared_context 'with unsuccessful unpublish request' do
  before do
    raise 'item must be set with `let(:item)`' unless defined? item

    stub_request(:delete, "#{Settings.publish.colenda.base_url}/items/#{item.unique_identifier}")
      .with(
        headers: { 'Authorization': "Token token=#{Settings.publish.colenda.token}" }
      )
      .to_return(
        status: 500, body: { error: 'Crazy Solr error' }.to_json, headers: { 'Content-Type': 'application/json' }
      )
  end
end
