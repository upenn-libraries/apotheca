# frozen_string_literal: true

require 'system_helper'

describe 'Asset New Page' do
  let(:user) { create(:user, :admin) }
  let(:item) { persist(:item_resource) }

  before do
    sign_in user
    visit new_asset_path(item_id: item.id)
  end

  it 'requires a preservation file' do
    click_button 'Save'
    expect(page).not_to have_text('Successfully created asset')
  end

  it 'can create a new asset' do
    attach_file 'asset-file', Rails.root.join('spec/fixtures/files/trade_card/original/front.tif')
    click_button 'Save'
    expect(page).to have_text('Successfully created asset')
  end
end
