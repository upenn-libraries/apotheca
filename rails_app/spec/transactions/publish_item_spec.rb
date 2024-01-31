# frozen_string_literal: true

describe PublishItem do
  describe '#call' do
    shared_context 'with successful publish request' do
      before do
        stub_request(:post, "#{Settings.publish.url}/items")
          .with(
            body: { 'item' => a_hash_including('descriptive_metadata' => a_hash_including('title' => [{ 'value' => 'New Item'}])) },
            headers: { 'Content-Type': 'application/json', 'Authorization': "Token token=#{Settings.publish.token}" }
          )
          .to_return(status: 200, headers: { 'Content-Type': 'application/json' })
      end
    end

    let(:transaction) { described_class.new }
    let(:result) { transaction.call(id: item.id.to_s, updated_by: 'initiator@example.com') }
    let(:updated_item) { result.value! }

    context 'when iiif-compatible assets are present' do
      include_context 'with successful publish request'

      let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }

      include_examples 'creates a resource event', :publish_item, 'initiator@example.com', true do
        let(:resource) { updated_item }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'generated IIIF manifest' do
        expect(updated_item.iiif_manifest).to have_attributes(
          type: 'iiif_manifest', generated_at: be_a(DateTime), mime_type: 'application/json',
          file_id: be_a(Valkyrie::ID)
        )
      end

      it 'publishes item' do
        result
        expect(a_request(:post, "#{Settings.publish.url}/items")).to have_been_made
      end

      it 'adds expected publishing attributes' do
        expect(updated_item).to have_attributes(
          published: true, first_published_at: be_a(DateTime), last_published_at: be_a(DateTime)
        )
      end
    end

    context 'when no iiif-compatible assets are present' do
      include_context 'with successful publish request'

      let(:item) do
        asset = persist(:asset_resource, :with_preservation_file, :with_pdf_file)
        persist(:item_resource, asset_ids: [asset.id], structural_metadata: { arranged_asset_ids: [asset.id] })
      end

      include_examples 'creates a resource event', :publish_item, 'initiator@example.com', true do
        let(:resource) { updated_item }
      end

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'does not generate an IIIF manifest' do
        expect(updated_item.derivatives.find(&:iiif_manifest)).to be_nil
      end

      it 'publishes item' do
        result
        expect(a_request(:post, "#{Settings.publish.url}/items")).to have_been_made
      end

      it 'adds expected publishing attributes' do
        expect(updated_item).to have_attributes(
          published: true, first_published_at: be_a(DateTime), last_published_at: be_a(DateTime)
        )
      end
    end

    context 'when publishing endpoint responds with error' do
      before do
        stub_request(:post, "#{Settings.publish.url}/items")
          .with(
            body: be_a(String),
            headers: { 'Content-Type': 'application/json', 'Authorization': "Token token=#{Settings.publish.token}" }
          )
          .to_return(
            status: 500,
            body: { error: 'Crazy Solr error' }.to_json,
            headers: { 'Content-Type': 'application/json' }
          )
      end

      let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :error_publishing_item
      end

      it 'includes error message in json response' do
        expect(result.failure[:exception].message).to include 'Crazy Solr error'
      end
    end
  end
end
