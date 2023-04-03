# frozen_string_literal: true

describe 'Item New Page' do
  let(:user) { create(:user, :admin) }
  let(:item) { build(:item_resource) }

  include_context 'with successful requests to mint EZID'
  include_context 'with successful requests to update EZID'


  before do
    sign_in user
    visit new_item_path
  end

  context 'when required fields are blank' do

    it 'requires human readable name' do
      click_on 'Save'
      expect(page).to have_text("Human readable name can't be blank")
    end

    it 'requires title' do
      click_on 'Save'
      expect(page).to have_text("Title can't be blank")
    end

    it 'requires viewing direction' do
      click_on 'Save'
      expect(page).to have_text('Viewing direction is not included in the list')
    end

    it 'requires viewing hint' do
      click_on 'Save'
      expect(page).to have_text('Viewing hint is not included in the list')
    end
  end

  context 'when required fields are present' do

    before do
      fill_in 'item-human-readable-name', with: item.human_readable_name
      fill_in 'item-descriptive-metadata-title', with: item.descriptive_metadata.title.first
      select ItemChangeSet::StructuralMetadataChangeSet::VIEWING_HINTS.first,
             from: 'item-structural-metadata-viewing-hint'
      select ItemChangeSet::StructuralMetadataChangeSet::VIEWING_DIRECTIONS.first,
             from: 'item-structural-metadata-viewing-direction'
    end

    it 'can create a new item' do
      click_on 'Save'
      expect(page).to have_text('Successfully created item')
    end
  end
end
