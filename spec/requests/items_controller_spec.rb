# frozen_string_literal: true

describe 'Items Requests' do
  it 'redirects unauthenticated users to sign in' do
    get '/resources/items'
    expect(response).to redirect_to(root_path)
    expect(flash['alert']).to include 'You need to sign in'
  end

  context 'when editing' do
    let(:item) { persist(:item_resource) }

    context 'without edit role' do
      it 'redirects viewer users to authenticated root path with authorization message' do
        sign_in create(:user, :viewer)
        get edit_item_path(item)
        expect(response).to redirect_to(authenticated_root_path)
        expect(flash['alert']).to include 'not authorized'
      end
    end

    context 'with proper role' do
      it 'shows item edit form' do
        sign_in create(:user, :editor)
        get edit_item_path(item)
        expect(response).to have_http_status :ok
      end
    end
  end
end
