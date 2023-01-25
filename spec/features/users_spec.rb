# frozen_string_literal: true

describe 'User management' do
  before { sign_in user }

  context 'with an Admin' do
    let(:user) { create(:user, :admin) }

    it 'lists all Users' do
      visit users_path
      expect(page).to have_text user.email
    end

    it 'creates a new admin User' do
      visit new_user_path
      fill_in 'user-email', with: 'test@user.com'
      click_on 'Save'
      expect(page).to have_text 'User created'
    end
  end
end
