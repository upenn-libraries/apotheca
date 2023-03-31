# frozen_string_literal: true

describe 'Bulk Import Index Page' do
  let(:user) { create :user, role }

  before { sign_in user }

  context 'with a viewer' do
    let(:role) { :viewer }

    before do
      create_list(:bulk_import, 1)
      visit bulk_imports_path
    end

    it 'lists all BulkImports' do
      expect(page).to have_text('.csv', count: 1)
      expect(page).to have_css('.bulk-imports-list__bulk-import', count: 1)
    end

    it 'does not show button to create new bulk import' do
      expect(page).not_to have_link('New Bulk Import', href: new_bulk_import_path)
    end

    it 'does not show cancel buttons' do
      expect(page).not_to have_link('Cancel')
    end
  end

  context 'with an editor' do
    let(:role) { :editor }
    let(:bulk_import) { create(:bulk_import, created_by: user) }

    before do
      create(:import, :queued, bulk_import: bulk_import)
      visit bulk_imports_path
    end

    it 'shows button to create new bulk import' do
      expect(page).to have_link('New Bulk Import', href: new_bulk_import_path)
    end

    it 'shows a cancel button' do
      expect(page).to have_button('Cancel', type: "submit")
    end

    it 'can cancel all queued imports' do
      click_on 'Cancel'
      expect(page).to have_text('All queued imports were cancelled')
      expect(page).not_to have_button('Cancel')
    end
  end

  context 'with an admin' do
    let(:role) { :admin }
    let(:bulk_import) { create(:bulk_import) }

    before do
      create(:import, :queued, bulk_import: bulk_import)
      visit bulk_imports_path
    end

    it 'shows button to create new bulk import' do
      expect(page).to have_link('New Bulk Import', href: new_bulk_import_path)
    end

    it 'can cancel others\' bulk imports' do
      expect(page).to have_button('Cancel', type: "submit")
      click_on 'Cancel'
      expect(page).to have_text('All queued imports were cancelled')
    end
  end

  context 'when searching bulk imports' do
    let(:user) { create :user, :viewer }
    let!(:first_bulk_import) { create(:bulk_import, original_filename: 'great_import.csv') }
    let!(:second_bulk_import) { create(:bulk_import, original_filename: 'lame_import.csv', note: 'awesome note!') }

    before do
      sign_in user
      visit bulk_imports_path
    end

    it 'returns the result with the query in the original_filename' do
      fill_in 'Search', with: 'great'
      click_on 'Submit'
      expect(page).to have_selector '.bulk-imports-list__bulk-import', count: 1
      import = find('.bulk-imports-list__bulk-import')
      expect(import).to have_text 'great_import.csv'
    end

    it 'returns the result with the query in the note' do
      fill_in 'Search', with: 'awesome'
      click_on 'Submit'
      expect(page).to have_selector '.bulk-imports-list__bulk-import', count: 1
      import = find('.bulk-imports-list__bulk-import')
      expect(import).to have_text 'lame_import.csv'
    end
  end

  context 'when filtering bulk imports by date range' do
    let(:user) { create :user, :viewer }
    let!(:first_bulk_import) { create(:bulk_import, original_filename: 'great_import.csv', created_at: Time.zone.local(2023, 02, 10, 12)) }
    let!(:second_bulk_import) { create(:bulk_import, original_filename: 'lame_import.csv', created_at: Time.zone.local(2023, 03, 17, 12)) }

    before do
      sign_in user
      params = { 'filter[start_date]' => '2023-03-07', 'filter[end_date]' => '2023-03-20' }
      visit bulk_imports_path(params)
    end

    it 'returns the result within the specified date rage' do
      expect(page).to have_selector '.bulk-imports-list__bulk-import', count: 1
      import = find('.bulk-imports-list__bulk-import')
      expect(import).to have_text 'lame_import.csv'
    end
  end

  context 'when filtering bulk imports by created_by' do
    let(:user) { create(:user, :viewer) }
    let(:other_user) { create(:user, :viewer) }
    let!(:user_bulk_import) { create(:bulk_import, created_by: user) }
    let!(:other_user_bulk_import) { create(:bulk_import, created_by: other_user) }

    before do
      sign_in user
      visit bulk_imports_path
    end

    it 'filters by associated user email' do
      select user.email, from: 'Created By'
      click_on 'Submit'
      expect(page).to have_text(user.email, count: 2)
      expect(page).to have_text(other_user.email, count: 1)
    end
  end
end

