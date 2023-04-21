# frozen_string_literal: true

describe 'file listing tool requests' do
  let(:params) { { drive: 'sceti_digitized', path: '/' } }

  before do
    sign_in create(:user, :viewer)
    post file_listing_tool_file_list_path, as: :json, params: params
  end

  context 'with a valid path' do
    it 'returns file list' do
      expect(response.parsed_body['filenames']).to eq('bell.wav; video.mov')
    end
  end

  context 'with an invalid path' do
    let(:params) { { drive: 'invalid_drive', path: '/' } }

    it 'returns invalid path error' do
      expect(response.parsed_body['error']).to eq('Path invalid!')
    end
  end
end

