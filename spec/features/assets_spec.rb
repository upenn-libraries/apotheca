# frozen_string_literal: true

require 'rails_helper'

describe 'Asset Management' do
  before { sign_in user }

  context 'with an admin' do
    let(:user) { create(:user, :admin) }
    let(:item) { persist(:item_resource, :with_assets_some_arranged) }

    before { visit "#{items_path}/#{item.id}#assets" }

    scenario 'viewing link to add and asset' do
      expect(page).to have_link('Add Asset', href: "#{new_asset_path}?item_id=#{item.id}")
    end

    scenario 'viewing input to edit asset thumbnail' do
      expect(page).to have_button(value: 'Set as Item Thumbnail', count: item.asset_ids.length)
    end

    scenario 'viewing links to edit asset' do
      expect(page).to have_link('Edit Asset', count: item.asset_ids.length)
    end
  end

  context 'with a viewer' do
    let(:user) { create(:user, :viewer) }
    let(:item) { persist(:item_resource) }

    before { visit "#{items_path}/#{item.id}#assets" }

    scenario 'viewing link to add and asset' do
      expect(page).not_to have_link('Add Asset', href: "#{new_asset_path}?item_id=#{item.id}")
    end

    scenario 'viewing input to edit asset thumbnail' do
      expect(page).not_to have_button(value: 'Set as Item Thumbnail')
    end

    scenario 'viewing links to edit asset' do
      expect(page).not_to have_link('Edit Asset')
    end

  end
end
