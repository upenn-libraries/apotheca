# frozen_string_literal: true

describe 'Asset Edit Page' do
  let(:user) { create(:user, :admin) }
  let(:item) { persist(:item_resource, :with_asset) }
  let(:asset_label) { 'Test' }

  before do
    sign_in user
    visit edit_asset_path(item.asset_ids.first)
  end

  it 'requires a preservation file when one has not been previously set' do
    fill_in 'asset-label', with: asset_label
    click_on 'Save'
    expect(page).to have_text("Preservation file can't be blank")
  end

  it 'can attach the preservation file' do
    attach_file 'asset-file', 'spec/fixtures/files/trade_card/front.tif'
    click_on 'Save'
    expect(page).to have_text('Successfully updated asset.')
  end

  it 'displays error message when preservation file has an unsupported file extension' do
    attach_file 'asset-file', 'spec/fixtures/imports/bulk_import_data.csv'
    click_on 'Save'
    expect(page).to have_text('Invalid File Extension')
  end

  it 'can update the asset' do
    fill_in 'asset-label', with: asset_label
    attach_file 'asset-file', 'spec/fixtures/files/trade_card/front.tif'
    click_on 'Save'
    expect(page).to have_text(asset_label)
    expect(page).to have_text('Successfully updated asset.')
  end
end
