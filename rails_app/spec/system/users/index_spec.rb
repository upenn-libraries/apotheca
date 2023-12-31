# frozen_string_literal: true

require 'system_helper'

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
    let(:names) do
      {
        user1_fname: 'Carla',
        user2_lname: 'Kanning',
        user3_fname: 'Bob',
        user3_lname: 'Smith'
      }
    end

    let(:user4_email) { 'jdoe@upenn.edu' }

    let(:user) do
      create(:user, :admin, first_name: names[:user1_fname], last_name: 'Galarza', email: 'cgalarza@upenn.edu')
    end

    before do
      create(:user, :admin, first_name: 'Michael', last_name: names[:user2_lname], email: 'mk@upenn.edu')
      create(:user, :editor, first_name: names[:user3_fname], last_name: names[:user3_lname], email: 'bobs@upenn.edu')
      create(:user, :viewer, first_name: 'Jane', last_name: 'Doe', email: user4_email, active: 0)

      visit users_path
    end

    it 'searches by first name' do
      fill_in 'Search', with: 'rl'
      click_button 'Filter'
      expect(page).to have_css '.users-list__user', count: 1
      expect(page).to have_text(names[:user1_fname])
    end

    it 'searches by last name' do
      fill_in 'Search', with: 'annin'
      click_button 'Filter'
      expect(page).to have_css '.users-list__user', count: 1
      expect(page).to have_text names[:user2_lname]
    end

    it 'searches by email' do
      fill_in 'Search', with: '@upenn'
      click_button 'Filter'
      expect(page).to have_css '.users-list__user', count: 4
      expect(page).to have_text names[:user2_lname]
    end

    it 'searches by full name' do
      fill_in 'Search', with: 'Bob Smith'
      click_button 'Filter'
      expect(page).to have_css '.users-list__user', count: 1
      expect(page).to have_text([names[:user3_fname], names[:user3_lname]].join(' '))
    end

    it 'filters by status' do
      select 'Active', from: 'Status'
      click_button 'Filter'
      expect(page).to have_css '.users-list__user', count: 3
      expect(page).not_to have_text user4_email
    end

    it 'filters by role' do
      select 'Viewer', from: 'Role'
      click_button 'Filter'
      expect(page).to have_css '.users-list__user', count: 1
      expect(page).to have_text user4_email
    end
  end
end
