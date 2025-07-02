# frozen_string_literal: true

describe 'IIIF Item API requests' do
  describe 'GET #manifest' do
    context 'when no resource is found' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        get iiif_api_item_manifest_path('1234-fooo-5678-quux')
      end

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_found')
      end
    end

    context 'when an item is not published' do
      let(:item) { persist(:item_resource, published: false) }

      before { get iiif_api_item_manifest_path(item.id) }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_published')
      end
    end

    context 'with an error that does not have explicit handling' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::StaleObjectError)
        get iiif_api_item_manifest_path('1234-fooo-5678-quux')
      end

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'when a IIIF manifest is available' do
      let(:item) { persist(:item_resource, :with_full_assets_all_arranged, :with_derivatives, :published) }

      before { get iiif_api_item_manifest_path(item.id) }

      it 'redirects to presigned URL' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['id']).to include item.id
      end

      it 'includes CORS headers' do
        expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      end
    end

    context 'when a IIIF manifest is not available' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged) }

      before { get iiif_api_item_manifest_path(item.id) }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.file_not_found')
      end
    end
  end
end
