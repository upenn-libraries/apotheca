# frozen_string_literal: true


describe 'BulkExport management' do

  let!(:bulk_exports) { create_list(:bulk_export, 10, state: BulkExport::STATE_QUEUED) }

  before do
    persist(:item_resource)
  end

  context 'with a viewer' do

    before do
      sign_in user
      visit bulk_exports_path
    end

    let(:user) { create(:user, :viewer) }

    it 'lists all BulkExports' do
      expect(page).to have_text('Search Parameters', count: bulk_exports.length)
      expect(page).to have_css('.card', count: bulk_exports.length)
    end

    it 'does not show any buttons' do
      visit bulk_exports_path
      expect(page).not_to have_button('Export')
    end
  end

  context 'with an editor' do

    let(:user) { create(:user, :editor) }
    let!(:bulk_export) { create(:bulk_export, user: user, state: BulkExport::STATE_QUEUED) }

    before do
      sign_in user
      visit bulk_exports_path
    end

    it 'lists all BulkExports' do
      expect(page).to have_text('Search Parameters', count: bulk_exports.length + 1)
      expect(page).to have_css('.card', count: bulk_exports.length + 1)
    end

    it 'only shows buttons for BulkExports that belong to user' do
      expect(page).to have_button('Export', count: 3)
    end
  end

  context 'with and admin' do

    let(:user) { create(:user, :admin) }

    before do
      sign_in user
      visit bulk_exports_path
    end

    it 'lists all BulkExports' do
      expect(page).to have_text('Search Parameters', count: bulk_exports.length)
      expect(page).to have_css('.card', count: bulk_exports.length)
    end

    it 'shows all the buttons' do
      expect(page).to have_button('Export', count: bulk_exports.length * 3)
    end
  end

  context 'with a processed bulk export' do

    let(:user) { create(:user, :viewer) }

    before do
      bulk_exports.each(&:process!)
      sign_in user
      visit bulk_exports_path
    end

    it 'shows a link to download the attached csv' do
      expect(page).to have_link('Download CSV', count: bulk_exports.length)
    end
  end

end
