# frozen_string_literal: true

require 'system_helper'

describe 'Item Index Page' do
  let(:user) { create(:user, role) }
  let!(:item) { persist(:item_resource, :with_asset) }

  before do
    sign_in user
  end

  context 'without incorporated ILS metadata' do
    let(:role) { :viewer }

    before { visit items_path }

    it 'lists Item human readable name' do
      expect(page).to have_link item.human_readable_name, href: item_path(item)
    end

    it 'lists all Item title values' do
      titles = item.descriptive_metadata.title.pluck(:value)
      titles.each do |title|
        expect(page).to have_css 'tr li', text: title
      end
    end

    it 'selects the default sort options' do
      expect(find_field('Sort By').value).to eq ItemIndex::DEFAULT_SORT[:field]
      expect(find_field('Direction').value).to eq ItemIndex::DEFAULT_SORT[:direction]
    end

    it 'lists the items in descending order from newest to oldest' do
      expect(page.find('tbody tr:nth-child(1)')).to have_text(item.unique_identifier)
      second_item = persist(:item_resource)
      visit items_path do
        expect(page.find('tbody tr:nth-child(1)')).to have_text(second_item.unique_identifier)
      end
    end
  end

  context 'with incorporated ILS metadata' do
    include_context 'with successful Marmite request' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/non-book-1.xml')) }
    end

    let(:user) { create(:user, :viewer) }
    let(:item_with_bibnumber) { persist(:item_resource, :with_bibnumber) }

    before do
      item_with_bibnumber # build item after Marmite request has been stubbed
      visit items_path
    end

    it 'show ILS title' do
      expect(page).to have_text 'An account of the Epidemic Fever as it occurred in Botetourt County Virginia during the summer of the year eighteen hundred and twenty-one'
    end

    it 'shows resource collection' do
      expect(page).not_to have_text 'University of Pennsylvania Medical Dissertation Digital Library'
      expect(page).to have_text 'Fake Collection'
    end
  end

  context 'with an editor' do
    let(:role) { :editor }

    before { visit items_path }

    it 'shows link to create item' do
      expect(page).to have_link('Create Item', href: new_item_path)
    end

    it 'stores per page value across requests' do
      select '50', from: 'Rows'
      click_button 'Submit'
      click_link 'Exports'
      click_link 'Items'
      expect(page).to have_select('Rows', selected: '50')
    end
  end

  context 'with a viewer' do
    let(:role) { :viewer }

    before do
      visit items_path
    end

    it 'does not show link to create an item' do
      visit items_path
      expect(page).not_to have_link('Create Item', href: new_item_path)
    end
  end
end
