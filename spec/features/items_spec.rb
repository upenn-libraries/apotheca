# frozen_string_literal: true

require 'rails_helper'

describe 'Item management' do
  before { sign_in user }

  context 'with an admin' do
    let(:user) { create(:user, :admin) }
    let!(:item) { persist(:item_resource, :with_asset) }

    context 'when viewing item index page' do
      before { visit items_path }

      it 'shows link to create item' do
        expect(page).to have_link('Create Item', href: new_item_path)
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
    end
  end
end
