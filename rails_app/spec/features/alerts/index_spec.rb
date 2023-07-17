# frozen_string_literal: true

describe 'Alert Index Page' do
  before do
    sign_in user
    AlertMessage.create! [{ location: 'header' }, { location: 'home' }]
  end

  context 'with an Admin' do
    let(:user) { create(:user, :admin) }

    before { visit alert_messages_path }

    it 'can manage Alerts' do
      expect(page).to have_text 'Alert Messages'
    end

    it 'can update Alerts' do
      expect(page).not_to have_text('test message')
      find_by_id('alert-message-active', match: :first).check
      find_by_id('alert-message-message', match: :first).fill_in(with: 'test message')
      find_button('Save', match: :first).click
      within('.header-alert') { expect(page).to have_text('test message') }
    end
  end

  context 'with a Viewer' do
    let(:user) { create(:user, :viewer) }

    it 'cannot manage alerts' do
      visit alert_messages_path
      expect(page).to have_text 'You are not authorized'
    end
  end
end
