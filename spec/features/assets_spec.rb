# frozen_string_literal: true

require 'rails_helper'

describe 'Asset Management' do
  before { sign_in user }

  context 'with an admin' do
    let(:user) { create(:user, :admin) }
    let(:item) { persist(:item_resource) }

    before { visit "#{items_path}/#{item.id}#assets" }

    scenario 'viewing link to add and asset' do
      expect(page).to have_link('Add Asset', href: "#{new_asset_path}?item_id=#{item.id}")
    end
  end

  context 'with a viewer' do
    let(:user) { create(:user, :viewer) }
    let(:item) { persist(:item_resource) }

    before { visit "#{items_path}/#{item.id}#assets" }

    scenario 'viewing link to add and asset' do
      expect(page).not_to have_link('Add Asset', href: "#{new_asset_path}?item_id=#{item.id}")
    end
  end

end