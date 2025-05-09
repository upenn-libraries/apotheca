# frozen_string_literal: true

require 'system_helper'

describe 'Bulk Export New Page' do
  context 'when creating a bulk export' do
    let(:user) { create(:user, :viewer) }

    before do
      sign_in user
      persist(:item_resource)
      visit items_path
    end

    it 'has link to create bulk export' do
      expect(page).to have_text('Export as CSV')
    end

    context 'when redirected to bulk export new form' do
      before do
        fill_in 'Search', with: 'Green'
        click_button 'Submit'
        click_link 'Export as CSV'
      end

      it 'redirects to bulk export new form' do
        expect(page).to have_text('Create Bulk Export')
      end

      it 'fills Search Params field with search params' do
        expect(page).to have_field('bulk-export-search-params', disabled: true)
        field = find_field('bulk-export-search-params', disabled: true)
        expect(field.value).to have_text '"all" => "Green"'
      end

      it 'creates a bulk export and redirects to bulk export index page' do
        fill_in 'bulk-export-title', with: 'Green'
        click_button 'Create'
        expect(find(class: 'card-title')).to have_text('Green')
      end
    end

    context 'when creating a Bulk Export without filtered search parameters' do
      before do
        click_link 'Export as CSV'
        click_button 'Create'
      end

      it 'creates a Bulk Export' do
        expect(page).to have_text('Bulk export created')
      end
    end
  end
end
