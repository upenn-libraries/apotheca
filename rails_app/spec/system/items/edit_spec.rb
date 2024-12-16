# frozen_string_literal: true

require 'system_helper'

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
    fill_in 'item-descriptive-metadata-description', with: data
    first(:button, 'Save').click
    expect(page).to have_text('Successfully updated item')
  end

  it 'can update structural metadata' do
    find(:button, 'Structural Metadata').click
    select ItemChangeSet::StructuralMetadataChangeSet::VIEWING_DIRECTIONS.first,
           from: 'item-structural-metadata-viewing-direction'
    first(:button, 'Save').click
    expect(page).to have_text('Successfully updated item')
  end

  it 'can update administrative info' do
    find(:button, 'Administrative Info').click
    fill_in 'item-human-readable-name', with: data
    first(:button, 'Save').click
    expect(page).to have_text('Successfully updated item')
  end

  it 'shows descriptive metadata tab' do
    expect(page).to have_css('#descriptive-metadata-tab')
  end

  it 'shows structural metadata tab' do
    expect(page).to have_css('#structural-metadata-tab')
  end

  it 'shows administrative info tab' do
    expect(page).to have_css('#administrative-info-tab')
  end

  it 'shows derivatives tab' do
    expect(page).to have_css('#derivatives-tab')
  end

  it 'shows events tab' do
    expect(page).to have_css('#events-tab')
  end

  it 'shows actions tab' do
    expect(page).to have_css('#actions-tab')
  end

  it 'shows assets tab' do
    expect(page).to have_css('#assets-tab')
  end
end
