# frozen_string_literal: true

require 'rails_helper'

describe 'Item management' do
  before { sign_in user }

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
  end
end
