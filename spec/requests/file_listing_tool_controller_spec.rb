# frozen_string_literal: true

describe 'file listing tool requests' do
  before { sign_in create(:user, :viewer) }

  context 'with a valid path' do
    it 'returns file list' do
      params = { drive: 'sceti_digitized', path: '/' }
      post file_listing_tool_file_list_path, as: :json, params: params
      expect(response.parsed_body['filenames']).to eq('bell.wav; video.mov')
    end
  end

  context 'with an invalid path' do
    it 'returns invalid path error' do
      params = { drive: 'invalid_drive', path: '/' }
      post file_listing_tool_file_list_path, as: :json, params: params
      expect(response.parsed_body['error']).to eq('Path invalid!')
    end
  end
end

