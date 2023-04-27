# frozen_string_literal: true

describe 'Import requests' do
  context 'when viewing the Import show page' do
    let!(:bulk_import) { create(:bulk_import) }
    let!(:import) { create(:import, :queued, bulk_import: bulk_import) }

    context 'with an unauthorized user' do
      it 'redirects an unauthorized user' do
        get bulk_import_import_path(bulk_import, import)
        expect(response).to redirect_to(root_path)
        expect(flash['alert']).to include 'You need to sign in'
      end
    end

    context 'with an authorized user' do
      before { sign_in create(:user, :admin) }

      it 'shows bulk_export index page for authorized user' do
        get bulk_import_import_path(bulk_import, import)
        expect(response).to have_http_status :ok
      end

      it 'cancels the queued import' do
        patch cancel_bulk_import_import_path(bulk_import, import)
        expect(response).to redirect_to bulk_import_import_path(bulk_import, import)
        import.reload
        expect(import.state).to eq('cancelled')
      end
    end
  end
end
