# frozen_string_literal: true

describe PublishingService::Client do
  let(:endpoint) { PublishingService::Endpoint.digital_collections }
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
          'event' => 'publish',
          'data' => {
            'item' => {
              'id' => be_a(String),
              'ark' => start_with('ark:/'),
              'first_published_at' => end_with('Z'),
              'last_published_at' => end_with('Z'),
              'descriptive_metadata' => a_hash_including(
                'title' => [{ 'value' => 'New Item' }]
              ),
              'structural_metadata' => {
                'viewing_direction' => nil,
                'viewing_hint' => nil
              },
              'derivatives' => {
                'preview' => {
                  'mime_type' => 'image/jpeg',
                  'size_bytes' => be_a(Integer),
                  'url' => "http://example.org/v1/items/#{item.id}/preview"
                },
                'pdf' => {
                  'mime_type' => 'application/pdf',
                  'size_bytes' => be_a(Integer),
                  'url' => "http://example.org/v1/items/#{item.id}/pdf"
                },
                'iiif_manifest' => a_hash_including(
                  'mime_type' => 'application/json',
                  'size_bytes' => be_a(Integer),
                  'url' => "http://example.org/iiif/items/#{item.id}/manifest"
                )
              },
              'assets' => [
                {
                  'id' => be_a(String),
                  'label' => 'Front',
                  'preservation_file' => {
                    'original_filename' => 'front.tif',
                    'size_bytes' => 291_455,
                    'mime_type' => 'image/tiff',
                    'url' => start_with('http://example.org/v1/assets/').and(end_with('/preservation'))
                  },
                  'derivatives' => {
                    'thumbnail' => {
                      'size_bytes' => 7_499,
                      'mime_type' => 'image/jpeg',
                      'url' => start_with('http://example.org/v1/assets/').and(end_with('/thumbnail'))
                    },
                    'access' => nil
                  }
                },
                {
                  'id' => be_a(String),
                  'label' => nil,
                  'preservation_file' => {
                    'original_filename' => 'back.tif',
                    'size_bytes' => 291_455,
                    'mime_type' => 'image/tiff',
                    'url' => start_with('http://example.org/v1/assets/').and(end_with('/preservation'))
                  },
                  'derivatives' => {
                    'thumbnail' => {
                      'size_bytes' => 5_471,
                      'mime_type' => 'image/jpeg',
                      'url' => start_with('http://example.org/v1/assets/').and(end_with('/thumbnail'))
                    },
                    'access' => nil
                  }
                }
              ]
            }
          }
        }
      end

      before do
        stub_request(:post, "#{endpoint.host}/#{endpoint.webhook_path}")
          .with(
            body: expected_payload,
            headers: { 'Content-Type': 'application/json', 'Authorization': "Token token=#{endpoint.token}" }
          )
          .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
      end

      it 'makes publish request with expected payload' do
        client.publish(item)
        expect(a_request(:post, "#{endpoint.host}/#{endpoint.webhook_path}")).to have_been_made
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
        expect(a_request(:post, endpoint.webhook_url).with(body: hash_including(event: 'unpublish'))).to have_been_made
      end
    end

    context 'when request unsuccessful (but not 404)' do
      include_context 'with unsuccessful unpublish request'

      it 'raises an error' do
        expect { client.unpublish(item) }.to raise_error PublishingService::Client::Error, /Crazy Solr error/
      end
    end

    context 'when request returns 404' do
      let(:expected_payload) { { event: 'unpublish', data: { item: { id: item.id } } } }

      before do
        stub_request(:post, endpoint.webhook_url)
          .with(
            body: expected_payload,
            headers: { 'Authorization': "Token token=#{endpoint.token}" }
          )
          .to_return(status: 404, body: { error: 'Not Found' }.to_json, headers: { 'Content-Type': 'application/json' })
      end

      it 'makes unpublish request' do
        client.unpublish(item)
        expect(
          a_request(:post, endpoint.webhook_url).with(body: expected_payload)
        ).to have_been_made
      end

      it 'does not raise error' do
        expect { client.unpublish(item) }.not_to raise_error
      end
    end
  end
end
