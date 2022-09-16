# frozen_string_literal: true

require 'rails_helper'

describe 'Items Requests' do
  it 'redirects unauthenticated users to sign in' do
    get '/items'
    expect(response).to redirect_to(root_path)
    expect(flash['alert']).to include 'You need to sign in'
  end

  context 'when editing' do
    let(:item) { persist(:item_resource) }

    context 'without edit role' do
      it 'redirects viewer users to authenticated root path with authorization message' do
        sign_in create(:user, :viewer)
        get "/items/#{item.id}/edit"
        expect(response).to redirect_to(authenticated_root_path)
        expect(flash['alert']).to include 'not authorized'
      end
    end

    context 'with proper role' do
      it 'shows item edit form' do
        sign_in create(:user, :editor)
        get "/items/#{item.id}/edit"
        expect(response).to have_http_status :ok
      end
    end
  end
end
