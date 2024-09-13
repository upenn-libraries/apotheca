# frozen_string_literal: true

describe 'file listing tool requests' do
  before do
    sign_in create(:user, :viewer)
    post file_listing_tool_file_list_path, as: :json, params: params
  end

  context 'with a valid drive and path' do
    let(:params) { { drive: 'sceti_digitized', path: '/' } }

    it 'returns file list' do
      expect(response.parsed_body['filenames']).to eq('bell.wav; dummy.pdf; video.mov')
    end
  end

  context 'with an invalid path' do
    let(:params) { { drive: 'sceti_digitized', path: '/invalid_path' } }

    it 'returns invalid path error' do
      expect(response.parsed_body['error']).to eq('Path invalid!')
    end
  end

  context 'with an invalid drive' do
    let(:params) { { drive: 'invalid_drive', path: '/' } }

    it 'returns invalid path error' do
      expect(response.parsed_body['error']).to eq('Path invalid!')
    end
  end

  context 'with a valid path and no files' do
    let(:params) { { drive: 'sceti_digitized', path: '/folder1' } }

    it 'returns no files' do
      expect(response.parsed_body['filenames']).to be_nil
    end
  end
end
