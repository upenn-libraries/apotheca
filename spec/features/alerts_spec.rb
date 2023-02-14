# frozen_string_literal: true

describe 'Alert management' do
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
      find(:checkbox).check
      find(:fillable_field).fill_in(with: 'test message')
      click_on('Save')
      expect(page).to have_text('test message', count: 2)
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
