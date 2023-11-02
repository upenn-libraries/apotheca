# frozen_string_literal: true

require 'system_helper'

describe 'Asset Show Page' do
  let(:user) { create(:user, role) }
  let(:asset) { persist(:asset_resource) }
  let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

  before do
    sign_in user
    visit asset_path(item.asset_ids.first)
  end

  shared_examples_for 'any logged in user' do
    it 'shows original filename' do
      expect(page).to have_text(asset.original_filename)
    end

    it 'shows the amount of derivatives on the derivatives tab' do
      expect(page).to have_button("Derivatives #{asset.derivatives.count}", exact: true)
    end

    it 'disables the derivatives tab if asset has no derivatives' do
      expect(page).to have_button("Derivatives #{asset.derivatives.count}", exact: true, class: 'disabled')
    end

    it 'displays timestamps in the same timezone' do
      expect(page).to have_text(asset.date_created.to_fs(:display), count: 2)
    end

    it 'shows download button for preservation file' do
      click_button 'Preservation File'
      expect(page).to have_link('Download Preservation File')
    end
  end

  shared_examples_for 'any logged in user who can edit Assets' do
    it 'shows link to edit assets' do
      expect(page).to have_link('Edit Asset')
    end

    it 'shows button to regenerate derivatives' do
      click_button 'Actions'
      expect(page).to have_button('Regenerate Derivatives')
    end

    it 'can regenerate derivatives' do
      click_button 'Actions'
      click_button 'Regenerate Derivatives'
      within('div.modal-content') { click_button 'Regenerate' }
      expect(page).to have_text('Successfully enqueued job to regenerate derivatives')
    end
  end

  shared_examples_for 'any logged in user who cannot delete Assets' do
    it 'does not show the button to delete Asset' do
      expect(page).not_to have_button('Delete Asset')
    end
  end

  context 'with a logged in viewer' do
    let(:role) { :viewer }

    it_behaves_like 'any logged in user'
    it_behaves_like 'any logged in user who cannot delete Assets'

    it 'does not show link to Edit Asset' do
      expect(page).not_to have_link('Edit Asset')
    end

    it 'does not show button to regenerate derivatives' do
      expect(page).not_to have_button('Regenerate Derivatives')
    end
  end

  context 'with a logged in editor' do
    let(:role) { :editor }

    it_behaves_like 'any logged in user'
    it_behaves_like 'any logged in user who can edit Assets'
    it_behaves_like 'any logged in user who cannot delete Assets'
  end

  context 'with a logged in admin' do
    let(:role) { :admin }

    it_behaves_like 'any logged in user'
    it_behaves_like 'any logged in user who can edit Assets'

    it 'shows the button to delete an Asset' do
      click_button 'Actions'
      expect(page).to have_button('Delete Asset')
    end
  end
end
