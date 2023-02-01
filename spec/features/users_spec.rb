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

  context 'with User searching and filtering' do
    let(:user) { create(:user, :admin, first_name: 'Carla', last_name: 'Galarza', email: 'cgalarza@upenn.edu') }

    before do
      @user2 = create(:user, :admin, first_name: 'Michael', last_name: 'Kanning', email: 'mk@upenn.edu')
      @user3 = create(:user, :editor, first_name: 'Bob', last_name: 'Smith', email: 'bsmith@upenn.edu')
      @user4 = create(:user, :viewer, first_name: 'Jane', last_name: 'Doe', email: 'jdoe@upenn.edu', active: false)

      visit users_path
    end

    it 'searches by first name' do
      fill_in 'Search', with: 'rl'
      click_on 'Filter'
      expect(page).to have_selector 'tr.user', count: 1
      expect(page).to have_text(user.email)
    end

    it 'searches by last name' do
      fill_in 'Search', with: '@upenn'
      click_on 'Filter'
      expect(page).to have_selector 'tr.user', count: 4
    end

    it 'searches by email' do
      fill_in 'Search', with: 'mk'
      click_on 'Filter'
      expect(page).to have_selector 'tr.user', count: 1
      expect(page).to have_text(@user2.email)
    end

    it 'searches by full name' do
      fill_in 'Search', with: 'Bob Smith'
      click_on 'Filter'
      expect(page).to have_selector 'tr.user', count: 1
      expect(page).to have_text(@user3.email)
    end

    it 'filters by status' do
      select 'Active', from: 'Status'
      click_on 'Filter'
      expect(page).to have_selector 'tr.user', count: 3
      expect(page).not_to have_text @user4.email
    end

    it 'filters by role' do
      select 'Viewer', from: 'Role'
      click_on 'Filter'
      expect(page).to have_selector 'tr.user', count: 1
      expect(page).to have_text @user4.email
    end
  end
end
