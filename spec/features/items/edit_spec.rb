# frozen_string_literal: true

describe 'Item Edit Page' do
  let(:user) { create(:user, :admin) }
  let(:item) { persist(:item_resource, :with_asset) }
  let(:data) { 'Test' }

  include_context 'with successful requests to update EZID'

  before do
    sign_in user
    visit edit_item_path(item)
  end

  it 'can update descriptive metadata' do
    fill_in 'item-descriptive-metadata-abstract', with: data
    first(:button, 'Save').click
    expect(page).to have_text('Successfully updated item')
  end

  it 'can update structural metadata' do
    select ItemChangeSet::StructuralMetadataChangeSet::VIEWING_DIRECTIONS.first,
           from: 'item-structural-metadata-viewing-direction'
    first(:button, 'Save').click
    expect(page).to have_text('Successfully updated item')
  end

  it 'can update administrative info' do
    fill_in 'item-human-readable-name', with: data
    first(:button, 'Save').click
    expect(page).to have_text('Successfully updated item')
  end
end
