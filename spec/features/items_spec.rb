# frozen_string_literal: true

describe 'Item management' do
  before { sign_in user }

  context 'with incorporated ILS metadata' do
    let(:marc_xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    let(:user) { create(:user, :viewer) }
    let(:item) { persist(:item_resource, :with_bibnumber) }

    before do
      stub_request(:get, "https://marmite.library.upenn.edu:9292/api/v2/records/sample-bib/marc21?update=always")
        .to_return(status: 200, body: marc_xml, headers: {})
      item # build item after Marmite request has been stubbed
      visit items_path
    end

    it 'shows ILS metadata on the index page' do
      expect(page).to have_text 'Edgar Fahs Smith Memorial Collection'
    end
  end

  context 'with an admin' do
    let(:user) { create(:user, :admin) }
    let!(:item) { persist(:item_resource, :with_asset) }

    context 'when viewing item index page' do
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

    context 'when viewing item show page' do
      before { visit "#{items_path}/#{item.id}" }

      it 'shows link to edit item on descriptive metadata tab' do
        expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#descriptive")
      end

      it 'shows link to edit item on structural metadata tab' do
        expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#structural")
      end

      it 'shows link to edit item on administrative info tab' do
        expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#administrative-info")
      end

      it 'shows button to delete the item on administrative info tab' do
        within '#administrative-info' do
          expect(page).to have_button('Delete Item')
        end
      end
    end

  end

  context 'with a viewer' do
    let(:user) { create(:user, :viewer) }
    let!(:item) { persist(:item_resource, :with_asset) }

    context 'when viewing item index page' do

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

      it 'does not show link to create an item' do
        visit items_path
        expect(page).not_to have_link('Create Item', href: new_item_path)
      end
    end

    context 'when viewing item show page' do
      before { visit "#{items_path}/#{item.id}" }

      it 'does not show link to edit item on descriptive metadata tab' do
        expect(page).not_to have_link('Edit', href: "#{items_path}/#{item.id}/edit#descriptive")
      end

      it 'does not show link to edit item on structural metadata tab' do
        expect(page).not_to have_link('Edit', href: "#{items_path}/#{item.id}/edit#structural")
      end

      it 'does not show link to edit item on administrative info tab' do
        expect(page).not_to have_link('Edit', href: "#{items_path}/#{item.id}/edit#administrative-info")
      end

      it 'does not show button to set item thumbnail on assets tab' do
        expect(page).not_to have_button(value: 'Set as Item Thumbnail')
      end

      it 'does not show link to delete an item on the administrative info tab' do
        visit item_path(item)
        within '#administrative-info' do
          expect(page).not_to have_button('Delete Item')
        end
      end

      it 'links title of asset to asset show page' do
        visit item_path(item)

        within "#asset-#{item.asset_ids.first}" do
          expect(page).to have_link('front.tif', href: asset_path(item.asset_ids.first))
        end
      end
    end
  end
end
