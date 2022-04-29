# frozen_string_literal: true

require "rails_helper"

describe ItemsController do
  it 'redirects unauthenticated users to sign in'do
    get '/items'
    expect(response).to redirect_to(root_path)
    expect(flash['alert']).to include 'You need to sign in'
  end

  context 'edit' do
    it 'redirects viewer users to authenticated root path with authorization message' do
      sign_in(create :user, :viewer)
      get '/items/1/edit'
      expect(response).to redirect_to(authenticated_root_path)
      expect(flash['alert']).to include 'not authorized'
    end
  end
end
