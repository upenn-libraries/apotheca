# frozen_string_literal: true

describe CSVImport::ProcessFiles do
  describe '#call' do
    let(:csv_filename) { 'bulk_import_expecting_assets_csv.csv' }
    let(:csv_file) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: File.new(Rails.root.join("spec/fixtures/imports/#{csv_filename}")),
        filename: csv_filename
      )
    end

    let(:asset_csv_files) do
      [ActionDispatch::Http::UploadedFile.new(tempfile: File.new(Rails.root.join('spec/fixtures/imports/assets.csv')),
                                              filename: 'assets.csv')]
    end

    let(:result) { described_class.new.call(csv_file, asset_csv_files) }
    let(:csv) { result.value! }

    context 'with all asset CSVs provided' do
      it 'returns success' do
        expect(result.success?).to be true
      end

      it 'removes csv_filename column' do
        expect(csv.first.key?('csv_filename')).to be false
      end

      it 'adds asset using long format specification' do
        expect(csv.first['assets']['arranged'].first).to eq('annotation' => ['first annotation', 'second annotation'],
                                                            'filename' => 'front.tif', 'label' => '1v')

        expect(csv.first['assets']['arranged'].last).to eq('annotation' => [], 'filename' => 'back.tif',
                                                           'label' => '1r')
      end
    end

    context 'with unreferenced asset CSV' do
      let(:csv_filename) { 'bulk_import_data.csv' }

      it 'returns failure' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :asset_csv_not_referenced
      end
    end

    context 'with no asset CSV references' do
      let(:csv_filename) { 'bulk_import_data.csv' }
      let(:asset_csv_files) { [] }

      it 'returns success' do
        expect(result.success?).to be true
      end
    end

    context 'with malformed CSV' do
      let(:csv_filename) { 'bulk_import_data_with_malformed_csv.csv' }

      it 'returns failure' do
        expect(result.failure?).to be true
        expect(result.failure).to include(error: :malformed_csv, file: 'bulk_import_data_with_malformed_csv.csv')
      end
    end
  end

  describe '#validate' do
    let(:csv) { StructuredCSV.parse(contents) }
    let(:result) { described_class.new.validate(csv) }

    context 'with empty csv' do
      let(:contents) { Rails.root.join('spec/fixtures/imports/bulk_import_without_item_data.csv').read }

      it 'returns failure monad' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to be :empty_csv
      end
    end

    context 'with missing asset CSVs' do
      let(:contents) { Rails.root.join('spec/fixtures/imports/bulk_import_expecting_assets_csv.csv').read }

      it 'return failure monad' do
        expect(result.failure?).to be true
        expect(result.failure).to include(error: :missing_asset_csv, missing: 'assets.csv')
      end
    end
  end

  describe '#normalize_asset_data' do
    let(:assets_data) do
      [{ 'filename' => 'a.tif', 'sequence' => '2', 'annotation' => ['scribble'] },
       { 'filename' => 'b.tif', 'label' => 'test', 'transcription' => %w[readable text], 'sequence' => nil },
       { 'filename' => 'c.tif', 'sequence' => '10' }]
    end

    let(:transformed_data) { described_class.new.normalize_asset_data(assets_data) }

    it 'adds assets with sequence to arranged assets array' do
      expect(transformed_data['arranged'].size).to eq(2)
      expect(transformed_data['arranged']).to eq [
        { 'filename' => 'a.tif', 'annotation' => ['scribble'] },
        { 'filename' => 'c.tif' }
      ]
    end

    it 'adds assets with no sequence to unarranged assets array' do
      expect(transformed_data['unarranged'].size).to eq(1)
      expect(transformed_data['unarranged'].first).to eq('filename' => 'b.tif', 'label' => 'test',
                                                         'transcription' => %w[readable text])
    end
  end
end
