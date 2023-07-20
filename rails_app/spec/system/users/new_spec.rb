# frozen_string_literal: true

require 'system_helper'

describe 'User New Page' do
  let(:user) { create(:user, :admin) }

  before do
    sign_in user
    visit new_user_path
  end

  it 'creates a new admin User' do
    fill_in 'user-email', with: 'test@user.com'
    click_on 'Save'
    expect(page).to have_text 'User created'
  end
end
