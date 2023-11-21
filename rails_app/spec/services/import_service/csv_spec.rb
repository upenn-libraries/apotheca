# frozen_string_literal: true

describe ImportService::CSV do
  let(:contents) { '' }
  let(:csv) { described_class.new(contents) }

  describe '#add_asset_csv' do
    context 'with all asset CSVs provided' do
      let(:contents) { Rails.root.join('spec/fixtures/imports/bulk_import_expecting_assets_csv.csv').read }
      let(:asset_csv_contents) { Rails.root.join('spec/fixtures/imports/assets.csv').read }

      before { csv.add_assets_csv('assets.csv', asset_csv_contents) }

      it 'adds asset using long format specification' do
        expect(csv.first['assets']['arranged'].first).to eq('annotation' => ['first annotation', 'second annotation'],
                                                            'filename' => 'front.tif', 'label' => '1v')

        expect(csv.first['assets']['arranged'].last).to eq('annotation' => [], 'filename' => 'back.tif',
                                                           'label' => '1r')
      end
    end

    context 'with missing asset CSVs' do
      let(:contents) { Rails.root.join('spec/fixtures/imports/bulk_import_data.csv').read }
      let(:asset_csv_contents) { Rails.root.join('spec/fixtures/imports/assets.csv').read }

      it 'raises an error' do
        expect {
          csv.add_assets_csv('assets.csv', asset_csv_contents)
        }.to raise_error(ImportService::CSV::Error, 'Missing asset CSV(s): assets.csv')
      end
    end
  end

  describe '#valid!' do
    context 'with empty csv' do
      let(:contents) { Rails.root.join('spec/fixtures/imports/bulk_import_without_item_data.csv').read }

      it 'raises error when csv is empty' do
        expect { csv.valid! }.to raise_error(ImportService::CSV::Error, 'CSV has no data')
      end
    end

    context 'with missing asset CSVs' do
      let(:contents) { Rails.root.join('spec/fixtures/imports/bulk_import_expecting_asset_spreadsheets.csv').read }

      it 'raises error when any asset CSVs are missing' do
        expect { csv.valid! }.to raise_error(ImportService::CSV::Error,
                                             'Missing asset metadata CSVs: asset_metadata.csv')
      end
    end
  end
end
