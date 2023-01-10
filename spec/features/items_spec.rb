# frozen_string_literal: true

require 'rails_helper'

describe 'Item management' do
  before { sign_in user }

  context 'with an admin' do
      let(:user) { create(:user, :admin) }
      let!(:item) { persist(:item_resource) }

      scenario 'viewing create item link' do
        visit items_path
        expect(page).to have_link('Create Item', href: new_item_path)
      end

      scenario 'viewing edit item link on descriptive metadata tab' do
        visit "#{items_path}/#{item.id}"
        expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#descriptive")
      end

      scenario 'viewing edit item link on structural metadata tab' do
        visit "#{items_path}/#{item.id}"
        expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#structural")
      end

      scenario 'viewing edit item link on administrative info tab' do
        visit "#{items_path}/#{item.id}"
        expect(page).to have_link('Edit', href: "#{items_path}/#{item.id}/edit#administrative-info")
      end
    end


  context 'with a viewer' do
    let(:user) { create(:user, :viewer) }
    let!(:item) { persist(:item_resource) }

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

    scenario 'viewing create item link' do
      visit items_path
      expect(page).not_to have_link('Create Item', href: new_item_path)
    end

    scenario 'viewing edit item link on descriptive metadata tab' do
      visit "#{items_path}/#{item.id}"
      expect(page).not_to have_link('Edit', href: "#{items_path}/#{item.id}/edit#descriptive")
    end

    scenario 'viewing edit item link on structural metadata tab' do
      visit "#{items_path}/#{item.id}"
      expect(page).not_to have_link('Edit', href: "#{items_path}/#{item.id}/edit#structural")
    end

    scenario 'viewing edit item link on administrative info tab' do
      visit "#{items_path}/#{item.id}"
      expect(page).not_to have_link('Edit', href: "#{items_path}/#{item.id}/edit#administrative-info")
    end
  end
end
