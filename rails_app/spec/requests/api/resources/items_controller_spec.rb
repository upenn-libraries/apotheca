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

    xit 'returns item information' # TODO: pending implementation
  end

  describe 'GET #lookup' do
    xit 'returns item information for a given ARK' # TODO: pending implementation
  end

  describe 'GET #preview' do
    xit 'redirects to an image URL' # TODO: pending implementation
  end

  describe 'GET #pdf' do
    before { get api_item_pdf_path(item.id) }

    context 'when PDF is available' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives) }

      it 'redirects to a PDF download' do
        expected_presigned_url = %r{\A#{Settings.minio.endpoint}/#{Settings.derivative_storage.bucket}/#{item.id}/pdf}
        expect(response).to redirect_to(expected_presigned_url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end

    context 'when PDF is not available' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged) }

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
