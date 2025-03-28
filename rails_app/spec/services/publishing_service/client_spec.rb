# frozen_string_literal: true

describe PublishingService::Client do
  let(:endpoint) { PublishingService::Endpoint.colenda }
  let(:client) { described_class.new(endpoint) }

  describe '.new' do
    it 'creates connection' do
      expect(client.connection).to be_a Faraday::Connection
    end
  end

  describe '#publish' do
    let(:item) do
      resource = persist(:item_resource, :with_full_assets_all_arranged, :published, :with_derivatives)
      ItemChangeSet.new(resource)
    end

    context 'when request successful' do
      let(:expected_payload) do
        {
          'item' => {
            'id' => start_with('ark:/'),
            'uuid' => be_a(String),
            'first_published_at' => end_with('Z'),
            'last_published_at' => end_with('Z'),
            'descriptive_metadata' => a_hash_including(
              'title' => [{ 'value' => 'New Item' }]
            ),
            'iiif_manifest_path' => be_a(String),
            'pdf_path' => be_a(String),
            'thumbnail_asset_id' => be_a(String),
            'assets' => [
              {
                'id' => be_a(String),
                'filename' => 'front.tif',
                'iiif' => true,
                'original_file' => { 'path' => be_a(String), 'size' => 291_455, 'mime_type' => 'image/tiff' },
                'thumbnail_file' => { 'path' => be_a(String), 'size' => 7_499, 'mime_type' => 'image/jpeg' }
              },
              {
                'id' => be_a(String),
                'filename' => 'back.tif',
                'iiif' => true,
                'original_file' => { 'path' => be_a(String), 'size' => 291_455, 'mime_type' => 'image/tiff' },
                'thumbnail_file' => { 'path' => be_a(String), 'size' => 5_471, 'mime_type' => 'image/jpeg' }
              }
            ]
          }
        }
      end

      before do
        stub_request(:post, "#{endpoint.base_url}/items")
          .with(
            body: expected_payload,
            headers: { 'Content-Type': 'application/json', 'Authorization': "Token token=#{endpoint.token}" }
          )
          .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
      end

      it 'makes publish request with expected payload' do
        client.publish(item)
        expect(a_request(:post, "#{endpoint.base_url}/items")).to have_been_made
      end
    end

    context 'when request unsuccessful' do
      include_context 'with unsuccessful publish request'

      it 'raises an error' do
        expect { client.publish(item) }.to raise_error PublishingService::Client::Error, /Crazy Solr error/
      end
    end
  end

  describe '#unpublish' do
    let(:item) do
      resource = persist(:item_resource, :published)
      ItemChangeSet.new(resource)
    end

    context 'when request successful' do
      include_context 'with successful unpublish request'

      it 'makes unpublish request' do
        client.unpublish(item)
        expect(a_request(:delete, "#{endpoint.base_url}/items/#{item.unique_identifier}")).to have_been_made
      end
    end

    context 'when request unsuccessful (but not 404)' do
      include_context 'with unsuccessful unpublish request'

      it 'raises an error' do
        expect { client.unpublish(item) }.to raise_error PublishingService::Client::Error, /Crazy Solr error/
      end
    end

    context 'when request returns 404' do
      before do
        stub_request(:delete, "#{endpoint.base_url}/items/#{item.unique_identifier}")
          .with(
            headers: { 'Authorization': "Token token=#{endpoint.token}" }
          )
          .to_return(status: 404, body: { error: 'Not Found' }.to_json, headers: { 'Content-Type': 'application/json' })
      end

      it 'makes unpublish request' do
        client.unpublish(item)
        expect(a_request(:delete, "#{endpoint.base_url}/items/#{item.unique_identifier}")).to have_been_made
      end

      it 'does not raise error' do
        expect { client.unpublish(item) }.not_to raise_error
      end
    end
  end
end
