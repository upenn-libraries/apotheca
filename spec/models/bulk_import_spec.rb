# frozen_string_literal: true

describe BulkImport, type: :model do
  let(:bulk_import) do
    build :bulk_import, imports: build_list(:import, 1)
  end

  it 'has many Imports' do
    expect(bulk_import.imports.first).to be_a Import
  end

  it 'returns a User using created_by' do
    expect(bulk_import.created_by).to be_a User
  end

  it 'has timestamps' do
    expect(bulk_import).to respond_to :created_at, :updated_at
  end

  describe '#valid?' do
    context 'when created_by not present' do
      let(:bulk_import) { build(:bulk_import, created_by: nil) }

      it 'returns error' do
        expect(bulk_import.valid?).to be false
        expect(bulk_import.errors.messages[:created_by]).to include 'must exist'
      end
    end

    context 'when original_filename not present' do
      let(:bulk_import) { build(:bulk_import, original_filename: nil) }

      it 'returns error' do
        expect(bulk_import.valid?).to be false
        expect(bulk_import.errors.messages[:original_filename]).to include "can't be blank"
      end
    end
  end

  describe '.filter_created_between' do
    let!(:bulk_import1) { create(:bulk_import, created_at: '2022-01-01') }
    let!(:bulk_import2) { create(:bulk_import, created_at: '2022-02-01') }
    let!(:bulk_import3) { create(:bulk_import, created_at: '2022-03-01') }

    it 'filters bulk imports created between start and end date' do
      expect(described_class.filter_created_between('2021-12-31', '2022-02-02')).to match_array([bulk_import1, bulk_import2])
    end

    it 'filters bulk imports created after start date' do
      expect(described_class.filter_created_between('2022-01-31', nil)).to match_array([bulk_import2, bulk_import3])
    end

    it 'filters bulk imports created before end date' do
      expect(described_class.filter_created_between(nil, '2022-01-02')).to match_array([bulk_import1])
    end
  end

  describe '#aggregate_processing_time' do
    let(:import_1) { build(:import, :successful, duration: 60) }
    let(:import_2) { build(:import, :successful, duration: 120) }
    let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

    it 'sums the processing time of child DigitalObjectImports' do
      expect(bulk_import.aggregate_processing_time).to eq 180
    end
  end

  describe '#number_of_errors' do
    let(:import_1) { build(:import, :failed) }
    let(:import_2) { build(:import, :successful) }
    let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

    it 'returns completed' do
      expect(bulk_import.number_of_errors).to be 1
    end
  end

  describe '#csv' do
    let(:import) { build(:import, :successful) }
    let(:bulk_import) { create(:bulk_import, imports: [import]) }

    it 'returns the correct data' do
      expect(bulk_import.csv).to include import.import_data['action'], import.import_data['human_readable_name']
    end
  end

  describe '#uploaded_csv_empty?' do
    let(:bulk_import) { create(:bulk_import) }

    it 'returns true if csv has no item data' do
      csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_without_item_data.csv')
      expect(bulk_import).to be_uploaded_csv_empty(csv_path)
    end

    it 'returns false if csv has item data' do
      csv_path = Rails.root.join('spec/fixtures/imports/bulk_import_data.csv')
      expect(bulk_import).not_to be_uploaded_csv_empty(csv_path)
    end
  end

  describe '#state' do
    context 'when no imports are present' do
      let(:bulk_import) { create(:bulk_import) }

      it 'returns nil' do
        expect(bulk_import.state).to be_nil
      end
    end

    context 'when all imports are queued' do
      let(:import_1) { build(:import, :queued) }
      let(:import_2) { build(:import, :queued) }
      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns queued' do
        expect(bulk_import.state).to eql BulkImport::QUEUED
      end
    end

    context 'when any imports are processing' do
      let(:import_1) { build(:import, :processing) }
      let(:import_2) { build(:import, :queued) }
      let(:import_3) { build(:import, :cancelled) }
      let(:import_4) { build(:import, :failed) }

      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2, import_3, import_4]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when imports are successful or queued' do
      let(:import_1) { build(:import, :queued) }
      let(:import_2) { build(:import, :successful) }
      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when imports are cancelled or queued' do
      let(:import_1) { build(:import, :queued) }
      let(:import_2) { build(:import, :cancelled) }
      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when all completed imports have failed but some are still running' do
      let(:import_1) { build(:import, :failed) }
      let(:import_2) { build(:import, :processing) }
      let(:import_3) { build(:import, :queued) }

      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2, import_3]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when all imports are successful or cancelled' do
      let(:import_1) { build(:import, :successful) }
      let(:import_2) { build(:import, :cancelled) }

      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED
      end
    end

    context 'when all imports are successful' do
      let(:import_1) { build(:import, :successful) }
      let(:import_2) { build(:import, :successful) }
      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns completed' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED
      end
    end

    context 'when all imports failed' do
      let(:import_1) { build(:import, :failed) }
      let(:import_2) { build(:import, :failed) }
      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns completed' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED_WITH_ERRORS
      end
    end

    context 'when all imports are successful, failures, or cancelled' do
      let(:import_1) { build(:import, :failed) }
      let(:import_2) { build(:import, :successful) }
      let(:import_3) { build(:import, :cancelled) }

      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns completed' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED_WITH_ERRORS
      end
    end

    context 'when all imports are cancelled' do
      let(:import_1) { build(:import, :cancelled) }
      let(:import_2) { build(:import, :cancelled) }
      let(:bulk_import) { create(:bulk_import, imports: [import_1, import_2]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::CANCELLED
      end
    end
  end

  describe '#create_imports' do
    let(:bulk_import) { create(:bulk_import) }
    let(:csv_data) { Rails.root.join('spec/fixtures/imports/bulk_import_data.csv').read }

    before do
      bulk_import.create_imports(csv_data)
    end

    it 'creates imports' do
      bulk_import.reload
      expect(bulk_import.imports.count).to eq(1)
      expect(bulk_import.imports.first.human_readable_name).to eq('The Mermaids Singing are Beautiful')
    end

    it 'enqueues the job' do
      expect(ProcessImportJob).to have_been_enqueued
    end
  end
end
