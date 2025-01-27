# frozen_string_literal: true

require 'system_helper'

describe 'System Actions Page' do
  let(:user) { create(:user, role) }

  before { sign_in user }

  context 'when viewing the system actions page' do
    let(:role) { :admin }

    before { visit system_actions_path }

    it 'displays the bulk ILS refresh button' do
      expect(page).to have_button('Refresh All ILS Metadata')
    end
  end

  context 'when refreshing all ILS metadata' do
    let(:role) { :admin }

    before do
      visit system_actions_path
      find(:button, 'Refresh All ILS Metadata').click
      within('div.modal-content') { click_button 'Refresh' }
    end

    it 'returns to the system actions page' do
      expect(page).to have_current_path(system_actions_path)
    end

    it 'has the expected flash' do
      expect(page).to have_text I18n.t('actions.item.refresh_all_ILS.success')
    end

    it 'enqueues the job' do
      expect(EnqueueBulkRefreshIlsMetadataJob).to have_enqueued_sidekiq_job.with any_args
    end
  end
end
