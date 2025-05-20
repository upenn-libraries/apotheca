# frozen_string_literal: true

describe 'IIIF Resource Item API' do
  describe 'GET #show' do
    context 'when no resource is found' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        get api_item_resource_path('1234-fooo-5678-quux')
      end

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_found')
      end
    end

    context 'with an unpublished ItemResource' do
      let(:item) { persist(:item_resource) }

      before { get api_item_resource_path(item.id) }

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with an identifier for an AssetResource' do
      let(:asset) { persist(:asset_resource) }

      before { get api_item_resource_path(asset.id) }

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with an error that does not have explicit handling' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::StaleObjectError)
        get api_item_resource_path('1234-fooo-5678-quux')
      end

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'with ItemResource information only' do
      let!(:item) do
        persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives)
      end

      before { get api_item_resource_path(item.id, assets: 'true'), headers: { 'ACCEPT' => 'application/json' } }

      it 'returns item identifiers' do
        expect(json_body[:id]).to eq item.id.to_s
        expect(json_body[:ark]).to eq item.unique_identifier
      end

      it 'includes descriptive metadata' do
        expect(json_body).to have_key :descriptive_metadata
      end

      it 'includes item-level derivatives' do
        expect(json_body[:derivatives].flat_map(&:keys)).to include :pdf, :iiif_manifest
      end
    end

    context 'with AssetResource information included' do
      let(:item) { persist(:item_resource, :published) }
      let(:json) { get api_item_resource_path(item.id, assets: 'true'), headers: { 'ACCEPT' => 'application/json' } }

      it 'includes asset information if requested' do
        get api_item_resource_path(item.id, assets: 'true'), headers: { 'ACCEPT' => 'application/json' }
        expect(json_body).to be_present
      end
    end
  end

  describe 'GET #lookup' do
    xit 'returns item information for a given ARK' # TODO: pending implementation
  end

  describe 'GET #preview' do
    xit 'redirects to an image URL' # TODO: pending implementation
  end

  describe 'GET #pdf' do
    xit 'redirects to a PDF download' # TODO: pending implementation
  end
end
