# frozen_string_literal: true

describe 'Asset Requests' do
  before { sign_in create(:user, user_role) }

  # GET /resources/assets/:id/file/:type
  context 'when downloading files' do
    let(:user_role) { :viewer }

    context 'with errors' do
      let(:asset) { persist :asset_resource }

      it 'responds with a 400 when given an unsupported type' do
        get file_asset_path(asset, type: :monochrome)
        expect(response).to have_http_status :bad_request
      end

      it 'responds with a 500 when the requested asset does not exist' do
        get file_asset_path('bad-asset-uuid', type: :preservation)
        expect(response).to have_http_status :not_found
      end
    end

    context 'when the file exists' do
      let(:asset) { persist :asset_resource, :with_preservation_file }

      before { get file_asset_path(asset, type: :preservation) }

      it 'returns a successful response' do
        expect(response).to have_http_status :ok
      end

      it 'has the correct Content-Type header' do
        expect(response.headers['Content-Type']).to eq 'image/tiff'
      end

      it 'has the correct filename' do
        expect(response.headers['Content-Disposition']).to include 'filename="front.tif"'
      end

      it 'has the correct disposition' do
        expect(response.headers['Content-Disposition']).to include 'attachment;'
      end
    end
  end

  # POST /resources/assets
  context 'when creating asset' do
    let(:user_role) { :editor }
    let(:item) { persist :item_resource }
    let(:file) { fixture_file_upload('files/trade_card/original/front.tif') }

    context 'when an error is raised in UpdateAsset transaction' do
      before do
        # Returning a virus check failure when creating the asset.
        transaction_double = instance_double(UpdateAsset)
        allow(UpdateAsset).to receive(:new).and_return(transaction_double)
        allow(transaction_double).to receive(:call).with(any_args) do
          Dry::Monads::Failure.new(error: :virus_detected)
        end

        # Request
        post assets_path, params: { item_id: item.id, asset: { file: file } }
      end

      it 'displays error' do
        expect(response.body).to include 'Virus Detected'
      end

      it 'does not create an asset' do
        expect(
          Valkyrie::MetadataAdapter.find(:postgres).query_service.find_all_of_model(model: AssetResource).count
        ).to be 0
      end

      it 'does not record any events' do
        expect(ResourceEvent.all.count).to be 0
      end
    end

    context 'when uploading a file over 2GBs' do
      before do
        allow(ActionDispatch::Http::UploadedFile).to receive(:new).and_return(file)
        allow(file).to receive(:size).and_return(AssetsController::FILE_SIZE_LIMIT)

        post assets_path, params: { item_id: item.id, asset: { file: file } }
      end

      it 'displays a flash alert' do
        expect(flash[:alert]).to include(I18n.t('assets.file.size'))
      end
    end
  end

  # PATCH /resource/assets
  context 'when updating asset' do
    let(:user_role) { :editor }
    let(:asset) { persist :asset_resource }
    let(:item) { persist :item_resource }
    let(:file) { fixture_file_upload('files/trade_card/original/front.tif') }

    context 'when uploading a file over 2GBs' do
      before do
        allow(ActionDispatch::Http::UploadedFile).to receive(:new).and_return(file)
        allow(file).to receive(:size).and_return(AssetsController::FILE_SIZE_LIMIT)

        patch asset_path(asset), params: { item_id: item.id, asset: { file: file } }
      end

      it 'displays a flash alert' do
        expect(flash[:alert]).to include(I18n.t('assets.file.size'))
      end
    end
  end
end
