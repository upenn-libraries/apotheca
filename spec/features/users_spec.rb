# frozen_string_literal: true

require 'rails_helper'

describe 'User management' do
  before { sign_in user }

  context 'with an Admin' do
    let(:user) { create(:user, :admin) }

    scenario 'Listing all Users' do
      visit users_path
      expect(page).to have_text user.email
    end

    scenario 'creating a new admin User' do
      visit new_user_path
      fill_in :user_email, with: 'test@user.com'
      click_on 'Create User'
      expect(page).to have_text 'test@user.com'
    end
  end
end
