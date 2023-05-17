# frozen_string_literal: true

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
      titles = item.descriptive_metadata.title
      titles.each do |title|
        expect(page).to have_selector 'tr li', text: title
      end
    end

    it 'selects the default sort options' do
      expect(page).to have_select('Sort By', selected: 'Created At')
      expect(page).to have_select('Direction', selected: 'Descending')
    end

    it 'lists the items in descending order from newest to oldest' do
      expect(page.find('tbody tr:nth-child(1)')).to have_text(item.unique_identifier)
      second_item = persist(:item_resource, unique_identifier: 'second_item')
      visit items_path do
        expect(page.find('tbody tr:nth-child(1)')).to have_text(second_item.unique_identifier)
      end
    end
  end

  context 'with incorporated ILS metadata' do
    let(:user) { create(:user, :viewer) }
    let(:marc_xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    let(:item_with_bibnumber) { persist(:item_resource, :with_bibnumber) }

    before do
      stub_request(:get, 'https://marmite.library.upenn.edu:9292/api/v2/records/sample-bib/marc21?update=always')
        .to_return(status: 200, body: marc_xml, headers: {})
      item_with_bibnumber # build item after Marmite request has been stubbed
      visit items_path
    end

    it 'shows ILS metadata on the index page' do
      expect(page).to have_text 'Edgar Fahs Smith Memorial Collection'
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
      click_on 'Submit'
      click_on 'Exports'
      click_on 'Items'
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
