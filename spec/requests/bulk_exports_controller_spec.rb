# frozen_string_literal: true

describe 'BulkExport requests' do
  context 'when viewing the index page' do
    context 'with an unauthorized user' do
      it 'redirects an unauthorized user' do
        get '/bulk_exports'
        expect(response).to redirect_to(root_path)
        expect(flash['alert']).to include 'You need to sign in'
      end
    end

    context 'with an authorized user' do
      it 'shows bulk_export index page for authorized user' do
        sign_in create(:user, :admin)
        get '/bulk_exports'
        expect(response).to have_http_status :ok
      end
    end
  end

  context 'when deleting a bulk export' do
    let!(:viewer) { create(:user, :viewer) }
    let!(:bulk_export) { create(:bulk_export) }

    context 'with the owner' do
      it 'deletes the bulk export' do
        sign_in bulk_export.created_by
        expect {
          delete "/bulk_exports/#{bulk_export.id}"
        }.to change(BulkExport, :count).by(-1)
        expect(response).to redirect_to(bulk_exports_path)
      end
    end

    context 'with another user' do
      it 'does not delete the bulk export' do
        sign_in viewer
        expect {
          delete "/bulk_exports/#{bulk_export.id}"
        }.not_to change(BulkExport, :count)
        expect(response).to redirect_to(root_path)
        expect(flash['alert']).to include 'You are not authorized to access this area.'
      end
    end
  end

  context 'when cancelling a bulk export' do
    let!(:editor) { create(:user, :editor) }
    let!(:bulk_export) { create(:bulk_export, :queued) }

    context 'with an owner' do
      it 'cancels the bulk export' do
        sign_in bulk_export.created_by
        get "/bulk_exports/#{bulk_export.id}/cancel"
        expect(response).to redirect_to(bulk_exports_path)
        bulk_export.reload
        expect(bulk_export.state).to eq('cancelled')
      end
    end

    context 'with another user' do
      it 'does not cancel the bulk export' do
        sign_in editor
        get "/bulk_exports/#{bulk_export.id}/cancel"
        expect(response).to redirect_to(root_path)
        expect(flash['alert']).to include 'You are not authorized to access this area.'
        bulk_export.reload
        expect(bulk_export.state).to eq('queued')
      end
    end
  end
end
