# frozen_string_literal: true

describe 'Bulk Import New Page' do
  let(:user) { create(:user, :editor) }

  before do
    sign_in user
    visit new_bulk_import_path
  end

  it 'fills Created By with the current user' do
    expect(page).to have_field('bulk-import-created-by', with: user.email, disabled: true)
  end

  it 'successfully creates a bulk import' do
    csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_data.csv')
    attach_file('bulk-import-csv', csv_path)
    click_on 'Create'

    import = find_by_id('bulk-import-dl')
    expect(import).to have_text 'bulk_import_data.csv'
  end

  context 'when submitting a csv with no item data' do
    it 'does not create a bulk import if the csv has no item data' do
      csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_without_item_data.csv')
      attach_file('bulk-import-csv', csv_path)
      click_on 'Create'
      expect(page).to have_text 'Problem creating bulk import: CSV has no item data'
    end
  end
end