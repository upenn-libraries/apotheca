# frozen_string_literal: true

describe 'Asset Show Page' do
  let(:user) { create(:user, role) }
  let(:asset) { persist(:asset_resource) }
  let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

  before do
    sign_in user
    visit asset_path(item.asset_ids.first)
  end

  shared_examples_for 'any logged in user' do
    it 'shows asset id' do
      expect(page).to have_text(asset.id)
    end

    it 'shows original filename' do
      expect(page).to have_text(asset.original_filename)
    end
  end
  shared_examples_for 'any logged in user who can edit Assets' do
    it 'shows link to edit assets' do
      expect(page).to have_link('Edit Asset')
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
      expect(page).to have_button('Delete Asset')
    end
  end
end
