# frozen_string_literal: true

require 'system_helper'

describe 'Item Show Page' do
  let(:user) { create(:user, role) }

  before do
    login_as user
  end

  shared_examples_for 'any logged in user' do
    it 'shows human readable name' do
      expect(page).to have_text(item.human_readable_name)
    end

    it 'disables access copy link when access copy is not available' do
      click_on 'Assets'
      expect(page).to have_link('Download Access Copy', class: /disabled/)
    end
  end

  shared_examples_for 'any logged in user who can edit an Item' do
    it 'shows link to edit item within descriptive metadata tab' do
      expect(page).to have_link('Edit', href: "#{edit_item_path(item)}#descriptive-metadata")
    end

    it 'shows link to edit item within structural metadata tab' do
      click_button 'Structural Metadata'
      expect(page).to have_link('Edit', href: "#{edit_item_path(item)}#structural-metadata")
    end

    it 'shows link to edit item within administrative info tab' do
      click_button 'Administrative Info'
      expect(page).to have_link('Edit', href: "#{edit_item_path(item)}#administrative-info")
    end

    it 'disables button to refresh ils metadata when item has no bibnumber' do
      click_button 'Actions'
      expect(page).to have_button('Refresh ILS Metadata', disabled: true)
    end

    it 'shows link to add an asset within assets tab' do
      click_button 'Assets'
      expect(page).to have_link('Add Asset', href: new_asset_path(item_id: item.id))
    end

    it 'shows link to arrange assets within assets tab' do
      click_button 'Assets'
      expect(page).to have_link('Arrange Assets', href: reorder_assets_item_path(id: item.id))
    end

    it 'shows button to edit an asset within assets tab' do
      click_button 'Assets'
      expect(page).to have_link('Edit Asset', href: edit_asset_path(item.asset_ids.first))
    end

    it 'shows button to set item thumbnail' do
      click_button 'Assets'
      expect(page).to have_button('Set as Item Thumbnail')
    end

    it 'shows link to view all events within events tab' do
      click_button 'Events'
      expect(page).to have_link('View All Events', href: events_path(resource_id: item.id.to_s))
    end

    it 'shows button for derivatives tab' do
      expect(page).to have_button('Derivatives')
    end
  end

  context 'with incorporated ILS metadata' do
    include_context 'with successful Alma request' do
      let(:xml) { File.read(file_fixture('alma/marc_xml/book-1.xml')) }
    end

    let(:user) { create(:user, :viewer) }
    let(:item) { persist(:item_resource, :with_bibnumber) }

    before do
      item
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
      expect(page).to have_css('.bg-warning li',
                               text: 'Fake Collection')
    end

    it 'prioritizes ILS value if no resource value on descriptive metadata tab' do
      expect(page).to have_css('.bg-success li',
                               text: 'https://colenda.library.upenn.edu/catalog/81431-p3df6k90j')
    end

    it 'hides value row if no resource or ILS value on descriptive metadata tab' do
      expect(page).not_to have_text('Abstract')
    end

    context 'when refreshing ils metadata' do
      let(:user) { create(:user, :editor) }

      it 'enables the button to refresh ils metadata' do
        click_button 'Actions'
        expect(page).to have_button('Refresh ILS Metadata', disabled: false)
      end

      it 'enqueues job to refresh ils metadata' do
        click_button 'Actions'
        click_button 'Refresh ILS Metadata'
        within('div.modal-content') { click_button 'Refresh' }
        expect(page).to have_text('Job to refresh ILS metadata enqueued')
      end
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

    it 'does not show link to add an asset within assets tab' do
      expect(page).not_to have_link('Add Asset', href: new_asset_path(item_id: item.id))
    end

    it 'does not show link to arrange assets within assets tab' do
      expect(page).not_to have_link('Arrange Assets', href: reorder_assets_item_path(id: item.id))
    end

    it 'does not show link to edit an asset within assets tab' do
      expect(page).not_to have_link('Edit Asset', href: edit_asset_path(item.asset_ids.first))
    end

    it 'does not show actions tab' do
      expect(page).not_to have_css('#actions')
    end

    it 'does not show form input to set item thumbnail' do
      expect { find('input', id: 'set-as-item-thumbnail') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'links title of asset to asset show page' do
      visit item_path(item)
      click_button 'Assets'
      within "#asset-#{item.asset_ids.first}" do
        expect(page).to have_link('front.tif', href: asset_path(item.asset_ids.first))
      end
    end

    it 'does not show ILS column on descriptive metadata tab' do
      expect(page).not_to have_text('From ILS')
    end

    it 'does not highlight resource values on descriptive metadata tab' do
      expect(page).not_to have_css('.resource-value.bg-success')
    end
  end

  context 'with a logged in editor' do
    let(:role) { :editor }
    let!(:item) { persist(:item_resource, :with_asset) }

    before { visit item_path(item) }

    it_behaves_like 'any logged in user'
    it_behaves_like 'any logged in user who can edit an Item'

    it 'shows actions tab' do
      expect(page).to have_css('#actions-tab')
    end

    it 'does not show button to delete item' do
      expect(page).not_to have_button('Delete Item')
    end
  end

  context 'with a logged in admin' do
    let(:role) { :admin }
    let!(:item) { persist(:item_resource, :with_asset) }

    before { visit item_path(item) }

    it_behaves_like 'any logged in user'
    it_behaves_like 'any logged in user who can edit an Item'

    it 'shows actions tab' do
      expect(page).to have_css('#actions-tab')
    end

    it 'shows button to delete item' do
      click_button 'Actions'
      expect(page).to have_button('Delete Item')
    end
  end
end
