# frozen_string_literal: true

describe PublishingService::Client do
  let(:client) { described_class.new(url: Settings.publish.url, token: Settings.publish.token) }
  let(:url) { Settings.publish.url }

  describe '.new' do
    it 'creates connection' do
      expect(client.connection).to be_a Faraday::Connection
    end
  end

  describe '#publish' do
    let(:item) do
      resource = persist(:item_resource, :with_full_assets_all_arranged, :published, :with_iiif_manifest)
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
            'thumbnail_asset_id' => be_a(String),
            'assets' => [
              {
                'id' => be_a(String),
                'filename' => 'front.tif',
                'iiif' => true,
                'original_file' => { 'path' => be_a(String), 'size' => 291_455, 'mime_type' => 'image/tiff' },
                'thumbnail_file' => { 'path' => be_a(String), 'mime_type' => 'image/tiff' }
              },
              {
                'id' => be_a(String),
                'filename' => 'back.tif',
                'iiif' => true,
                'original_file' => { 'path' => be_a(String), 'size' => 291_455, 'mime_type' => 'image/tiff' },
                'thumbnail_file' => { 'path' => be_a(String), 'mime_type' => 'image/tiff' }
              }
            ]
          }
        }
      end

      before do
        stub_request(:post, "#{Settings.publish.url}/items")
          .with(
            body: expected_payload,
            headers: { 'Content-Type': 'application/json', 'Authorization': "Token token=#{Settings.publish.token}" }
          )
          .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
      end

      it 'makes publish request with expected payload' do
        client.publish(item)
        expect(a_request(:post, "#{Settings.publish.url}/items")).to have_been_made
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
      resource = persist(:item_resource, :published, :with_iiif_manifest)
      ItemChangeSet.new(resource)
    end

    context 'when request successful' do
      include_context 'with successful unpublish request'

      it 'makes unpublish request' do
        client.unpublish(item)
        expect(a_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")).to have_been_made
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
        stub_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")
          .with(
            headers: { 'Authorization': "Token token=#{Settings.publish.token}" }
          )
          .to_return(status: 404, body: { error: 'Not Found' }.to_json, headers: { 'Content-Type': 'application/json' })
      end

      it 'makes unpublish request' do
        client.unpublish(item)
        expect(a_request(:delete, "#{Settings.publish.url}/items/#{item.unique_identifier}")).to have_been_made
      end

      it 'does not raise error' do
        expect { client.unpublish(item) }.not_to raise_error
      end
    end
  end
end
