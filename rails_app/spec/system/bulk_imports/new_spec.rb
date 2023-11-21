# frozen_string_literal: true

require 'system_helper'

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
    click_button 'Create'

    import = find_by_id('bulk-import-dl')
    expect(import).to have_text 'bulk_import_data.csv'
  end

  context 'when creating a bulk import with asset metadata CSVs' do
    let(:asset_csv_path) { Rails.root.join('spec/fixtures/imports/asset_metadata.csv') }

    it 'successfully creates a bulk import' do
      bulk_import_csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_expecting_asset_spreadsheets.csv')
      attach_file('bulk-import-csv', bulk_import_csv_path)
      attach_file('bulk-import-asset-metadata', asset_csv_path)
      click_button 'Create'
      expect(page).to have_text 'Bulk import created'
    end
  end

  context 'when creating a bulk import with missing asset metadata CSVs' do
    let(:asset_csv_path) { Rails.root.join('spec/fixtures/imports/asset_metadata.csv') }

    it 'fails with correct error message' do
      bulk_import_csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_expecting_asset_spreadsheets.csv')
      attach_file('bulk-import-csv', bulk_import_csv_path)
      click_button 'Create'
      expect(page).to have_text ' Problem creating bulk import: Missing asset CSV(s): assets.csv'
    end
  end

  context 'when submitting a csv with no item data' do
    it 'does not create a bulk import if the csv has no item data' do
      csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_without_item_data.csv')
      attach_file('bulk-import-csv', csv_path)
      click_button 'Create'
      expect(page).to have_text 'Problem creating bulk import: CSV has no data'
    end
  end

  context 'when submitting a csv with duplicated headers' do
    it 'fails and displays a message with the cause of the failure' do
      csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_with_duplicated_headers.csv')
      attach_file('bulk-import-csv', csv_path)
      click_button 'Create'
      expect(page).to have_text 'Problem creating bulk import: CSV contains duplicated column names'
    end
  end

  context 'when submitting a csv with malformed row data' do
    it 'fails and displays a message with the cause of the failure' do
      csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_data_with_malformed_csv.csv')
      attach_file('bulk-import-csv', csv_path)
      click_button 'Create'
      expect(page).to have_text 'Problem creating bulk import: Illegal quoting in line 2'
    end
  end
end
