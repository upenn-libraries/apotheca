# frozen_string_literal: true

require 'rails_helper'

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
        expect(response.headers['Content-Type']).to eq 'image/jpg'
      end

      it 'has the correct filename' do
        expect(response.headers['Content-Disposition']).to include 'filename="front.jpg"'
      end

      it 'has the correct disposition' do
        expect(response.headers['Content-Disposition']).to include 'attachment;'
      end
    end
  end
end
