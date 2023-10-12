# frozen_string_literal: true

describe 'Asset requests' do
  context 'when downloading files' do
    before { sign_in create(:user, :admin) }

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

      before do
        sign_in create(:user, :viewer)
        get file_asset_path(asset, type: :preservation)
      end

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

  context 'when uploading files' do
    let(:asset) { persist :asset_resource }
    let(:item) { persist :item_resource }
    let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/trade_card/original/front.tif')) }

    before do
      sign_in create(:user, :admin)
      allow(ActionDispatch::Http::UploadedFile).to receive(:new).and_return(file)
      allow(file).to receive(:size).and_return(AssetsController::FILE_SIZE_LIMIT)
    end

    it 'does not load files 2 gb or larger when creating an asset' do
      post assets_path, params: { item_id: item.id, id: asset.id, asset: { file: file } }
      expect(flash[:alert]).to include(I18n.t('assets.file.size'))
    end

    it 'does not load files 2 gb or larger when updating an asset' do
      patch asset_path(asset), params: { item_id: item.id, id: asset.id, asset: { file: file } }
      expect(flash[:alert]).to include(I18n.t('assets.file.size'))
    end
  end
end
