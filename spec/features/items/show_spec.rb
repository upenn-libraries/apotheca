# frozen_string_literal: true

describe 'Item Show Page' do
  let(:user) { create(:user, role) }

  before do
    sign_in user
  end

  shared_examples_for 'any logged in user' do
    it 'shows human readable name' do
      expect(page).to have_text(item.human_readable_name)
    end
  end

  shared_examples_for 'any user who can edit an Item' do
    it 'shows link to edit item on descriptive metadata tab' do
      expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#descriptive")
    end

    it 'shows link to edit item on structural metadata tab' do
      expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#structural")
    end

    it 'shows link to edit item on administrative info tab' do
      expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#administrative-info")
    end
  end

  context 'with incorporated ILS metadata' do
    let(:user) { create(:user, :viewer) }
    let(:marc_xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    let(:item) { persist(:item_resource, :with_bibnumber) }

    before do
      stub_request(:get, 'https://marmite.library.upenn.edu:9292/api/v2/records/sample-bib/marc21?update=always')
        .to_return(status: 200, body: marc_xml, headers: {})
      item # build item after Marmite request has been stubbed
      visit item_path(item)
    end

    it 'shows ILS and resource columns on descriptive metadata tab' do
      expect(page).to have_text 'From ILS'
      expect(page).to have_text 'From Resource'
    end

    # For all descriptive metadata tests below:
    # Enter 9923478503503681 as item's bibnumber to view ILS test values
    # Necessary resource values specified in item_resource factory

    it 'shows that resource value has priority over ILS on descriptive metadata tab' do
      expect(page).to have_css('.text-decoration-line-through li',
                               text: 'Edgar Fahs Smith Memorial Collection')
      expect(page).to have_css('.bg-success li',
                               text: 'Fake Collection')
    end

    it 'prioritizes ILS value if no resource value on descriptive metadata tab' do
      expect(page).to have_css('.bg-success li',
                               text: 'https://colenda.library.upenn.edu/catalog/81431-p3df6k90j')
    end

    it 'hides value row if no resource or ILS value on descriptive metadata tab' do
      expect(page).not_to have_text('Abstract')
    end
  end

  context 'with a logged in viewer' do
    let(:role) { :viewer }
    let!(:item) { persist(:item_resource, :with_asset) }

    before { visit item_path(item) }

    it_behaves_like 'any logged in user'

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

    it 'does not show ILS column on descriptive metadata tab' do
      expect(page).not_to have_text('From ILS')
    end

    it 'does not highlight resource values on descriptive metadata tab' do
      expect(page).not_to have_selector('.resource-value.bg-success')
    end
  end

  context 'with a logged in admin' do
    let(:role) { :admin }
    let!(:item) { persist(:item_resource, :with_asset) }

    before { visit item_path(item) }

    it_behaves_like 'any logged in user'
    it_behaves_like 'any user who can edit an Item'

    it 'shows button to delete the item on administrative info tab' do
      within '#administrative-info' do
        expect(page).to have_button('Delete Item')
      end
    end
  end
end
