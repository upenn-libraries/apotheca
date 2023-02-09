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
end
