# frozen_string_literal: true

describe 'User Index Page' do
  before { sign_in user }

  context 'with an Admin' do
    let(:user) { create(:user, :admin) }

    it 'lists all Users' do
      visit users_path
      expect(page).to have_text user.email
    end
  end

  context 'with User searching and filtering' do
    let(:user1_fname) { 'Carla' }
    let(:user2_lname) { 'Kanning' }
    let(:user3_fname) { 'Bob' }
    let(:user3_lname) { 'Smith' }
    let(:user4_email) { 'jdoe@upenn.edu' }

    let(:user) { create(:user, :admin, first_name: user1_fname, last_name: 'Galarza', email: 'cgalarza@upenn.edu') }

    before do
      create(:user, :admin, first_name: 'Michael', last_name: user2_lname, email: 'mk@upenn.edu')
      create(:user, :editor, first_name: user3_fname, last_name: user3_lname, email: 'bobs@upenn.edu')
      create(:user, :viewer, first_name: 'Jane', last_name: 'Doe', email: user4_email, active: 0)

      visit users_path
    end

    it 'searches by first name' do
      fill_in 'Search', with: 'rl'
      click_on 'Filter'
      expect(page).to have_selector '.users-list__user', count: 1
      expect(page).to have_text(user1_fname)
    end

    it 'searches by last name' do
      fill_in 'Search', with: 'annin'
      click_on 'Filter'
      expect(page).to have_selector '.users-list__user', count: 1
      expect(page).to have_text user2_lname
    end

    it 'searches by email' do
      fill_in 'Search', with: '@upenn'
      click_on 'Filter'
      expect(page).to have_selector '.users-list__user', count: 4
      expect(page).to have_text user2_lname
    end

    it 'searches by full name' do
      fill_in 'Search', with: 'Bob Smith'
      click_on 'Filter'
      expect(page).to have_selector '.users-list__user', count: 1
      expect(page).to have_text([user3_fname, user3_lname].join(' '))
    end

    it 'filters by status' do
      select 'Active', from: 'Status'
      click_on 'Filter'
      expect(page).to have_selector '.users-list__user', count: 3
      expect(page).not_to have_text user4_email
    end

    it 'filters by role' do
      select 'Viewer', from: 'Role'
      click_on 'Filter'
      expect(page).to have_selector '.users-list__user', count: 1
      expect(page).to have_text user4_email
    end
  end
end
