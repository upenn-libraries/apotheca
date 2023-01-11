# frozen_string_literal: true

require 'rails_helper'

describe 'Alert management' do
  before do
    sign_in user
    AlertMessage.create! [{ location: 'header' }, { location: 'home' }]
  end

  context 'with an Admin' do
    let(:user) { create(:user, :admin) }

    scenario 'Managing Alerts' do
      visit alert_messages_path
      expect(page).to have_text 'Alert Messages'
    end
  end

  context 'with a Viewer' do
    let(:user) { create(:user, :viewer) }

    scenario 'Managing Alerts' do
      visit alert_messages_path
      expect(page).to have_text 'You are not authorized'
    end
  end
end
