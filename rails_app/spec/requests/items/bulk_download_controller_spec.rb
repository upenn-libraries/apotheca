# frozen_string_literal: true

describe 'Item Bulk Download Requests' do
  before { sign_in create(:user, :viewer) }

  context 'when bulk download preservation files' do
    let(:item) { persist(:item_resource, :with_full_asset) }

    before { get preservation_bulk_download_item_path(item.id) }

    it 'returns a successful response' do
      expect(response).to have_http_status :ok
    end

    it 'has the expected headers' do
      content_disposition = response.headers['Content-Disposition']
      expect(content_disposition).to include "filename=\"#{item.human_readable_name.parameterize}.zip\""
      expect(content_disposition).to include 'attachment;'
    end
  end
end
