# frozen_string_literal: true

describe 'Asset Management' do
  before { sign_in user }

  context 'with an admin' do
    let(:user) { create(:user, :admin) }
    let(:item) { persist(:item_resource, :with_asset) }

    before { visit "#{items_path}/#{item.id}#assets" }

    it 'shows the link to add and asset' do
      expect(page).to have_link('Add Asset', href: "#{new_asset_path}?item_id=#{item.id}")
    end

    it 'shows links to edit assets' do
      expect(page).to have_link('Edit Asset', count: item.asset_ids.length)
    end
  end

  context 'with a viewer' do
    let(:user) { create(:user, :viewer) }
    let(:item) { persist(:item_resource, :with_asset) }

    before { visit "#{items_path}/#{item.id}#assets" }

    it 'does not show link to add an asset' do
      expect(page).not_to have_link('Add Asset', href: "#{new_asset_path}?item_id=#{item.id}")
    end

    it 'does not show links to edit assets' do
      expect(page).not_to have_link('Edit Asset')
    end

  end
end
