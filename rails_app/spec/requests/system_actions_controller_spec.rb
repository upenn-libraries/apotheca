# frozen_string_literal: true

RSpec.describe 'SystemActions requests' do
  context 'with an unauthenticated user' do
    it 'redirects user to the root path' do
      get system_actions_path
      expect(response).to redirect_to(root_path)
      expect(flash['alert']).to include 'You need to sign in'
    end
  end

  context 'with an unauthorized user' do
    before { sign_in create(:user, :editor) }

    it 'shows the system actions index page' do
      get system_actions_path
      expect(response).to redirect_to(authenticated_root_path)
      expect(flash['alert']).to include 'not authorized'
    end
  end

  context 'with an authorized user' do
    before { sign_in create(:user, :admin) }

    it 'shows the system actions index page' do
      get system_actions_path
      expect(response).to have_http_status :ok
    end
  end
end
