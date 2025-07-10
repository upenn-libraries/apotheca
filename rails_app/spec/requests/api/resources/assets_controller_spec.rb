# frozen_string_literal: true

describe 'Resource Asset API requests' do
  describe 'GET #show' do
    context 'when no asset is found' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::ObjectNotFoundError)
        get api_asset_resource_path('1234-fooo-5678-quux')
      end

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_found')
      end
    end

    context 'when no item is found' do
      let(:asset) { persist(:asset_resource) }

      before { get api_asset_resource_path(asset.id) }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_found')
      end
    end

    context 'with an unpublished ItemResource' do
      let(:item) { persist(:item_resource, :with_full_assets_all_arranged) }

      before { get api_asset_resource_path(item.asset_ids.first) }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.not_published')
      end
    end

    context 'with an identifier for an ItemResource' do
      let(:item) { persist(:item_resource, :published, :with_full_assets_all_arranged) }

      before { get api_asset_resource_path(item.id) }

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:bad_request)
        expect(json_body[:message]).to eq I18n.t('api.exceptions.resource_mismatch', resource: AssetResource.to_s)
      end
    end

    context 'with an error that does not have explicit handling' do
      before do
        allow(Valkyrie::MetadataAdapter).to receive(:find).and_raise(Valkyrie::Persistence::StaleObjectError)
        get api_asset_resource_path('1234-fooo-5678-quux')
      end

      it 'returns a failure object with the expected values' do
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'with an identifier for an AssetResource' do
      let(:item) do
        persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives,
                asset1: persist(:asset_resource, :with_video_file, :with_derivatives, :with_metadata))
      end
      let(:asset) { item.arranged_assets.first }
      let(:asset_json) { json_body[:data][:asset] }

      before { get api_asset_resource_path(asset.id), headers: { 'ACCEPT' => 'application/json' } }

      it 'returns asset identifier' do
        expect(asset_json[:id]).to eq asset.id.to_s
      end

      it 'includes preservation file metadata' do
        expect(asset_json[:preservation_file]).to match(
          mime_type: asset.technical_metadata.mime_type,
          original_filename: asset.original_filename,
          size_bytes: asset.technical_metadata.size,
          url: a_string_starting_with('http://www.example.com/')
        )
      end

      it 'includes access derivative' do
        expect(asset_json[:derivatives][:access]).to match(
          mime_type: asset.access.mime_type,
          size_bytes: asset.access.size,
          url: a_string_starting_with('http://www.example.com/')
        )
      end

      it 'includes thumbnail derivative' do
        expect(asset_json[:derivatives][:thumbnail]).to match(
          mime_type: asset.thumbnail.mime_type,
          size_bytes: asset.thumbnail.size,
          url: a_string_starting_with('http://www.example.com/')
        )
      end

      it 'includes related item' do
        expect(json_body[:data][:related][:item]).to eql "http://www.example.com/v1/items/#{item.id}?assets=true"
      end
    end
  end

  describe 'GET #file' do
    let(:item) do
      persist(:item_resource, :published, :with_full_assets_all_arranged, :with_derivatives,
              asset1: persist(:asset_resource, :with_video_file, :with_derivatives, :with_metadata))
    end
    let(:asset) { item.arranged_assets.first }

    before { get api_asset_file_path(asset.id, file: file) }

    context 'when the file parameter is invalid' do
      let(:file)  { 'invalid' }

      it 'returns a 400 status code' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.invalid_param.file_type', type: file)
      end
    end

    context 'when requesting a thumbnail' do
      let(:file) { 'thumbnail' }

      it 'redirects to a thumbnail download' do
        url = %r{\A#{Settings.minio.endpoint}/#{Settings.derivative_storage.bucket}/#{asset.id}/#{file}}
        expect(response).to redirect_to(url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end

    context 'when requesting a thumbnail but none exists' do
      let(:item) { persist(:item_resource, :published, :with_asset) }
      let(:asset) { item.asset_ids.first }
      let(:file) { 'thumbnail' }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.file_not_found')
      end
    end

    context 'when requesting access derivative' do
      let(:file) { 'access' }

      it 'redirects to access derivative download' do
        url = %r{\A#{Settings.minio.endpoint}/#{Settings.derivative_storage.bucket}/#{asset.id}/#{file}}
        expect(response).to redirect_to(url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end

    context 'when requesting access derivative but none exists' do
      let(:item) { persist(:item_resource, :published, :with_asset) }
      let(:asset) { item.asset_ids.first }
      let(:file) { 'access' }

      it 'returns a 404 status code' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a failure object with the expected values' do
        expect(json_body[:status]).to eq 'fail'
        expect(json_body[:message]).to eq I18n.t('api.exceptions.file_not_found')
      end
    end

    context 'when requesting preservation file' do
      let(:file) { 'preservation' }

      it 'redirects to a preservation file download' do
        url = %r{\A#{Settings.minio.endpoint}/#{Settings.preservation_storage.bucket}/#{asset.id}/}
        expect(response).to redirect_to(url)
        expect(response).to have_http_status(:temporary_redirect)
      end
    end
  end
end
