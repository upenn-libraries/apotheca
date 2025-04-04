# frozen_string_literal: true

describe BulkImport do
  let(:bulk_import) do
    build(:bulk_import, imports: build_list(:import, 1))
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
    let!(:jan_bulk_import) { create(:bulk_import, created_at: '2022-01-01') }
    let!(:feb_bulk_import) { create(:bulk_import, created_at: '2022-02-01') }
    let!(:march_bulk_import) { create(:bulk_import, created_at: '2022-03-01') }

    it 'filters bulk imports created between start and end date' do
      expect(described_class.filter_created_between('2021-12-31',
                                                    '2022-02-02')).to contain_exactly(jan_bulk_import, feb_bulk_import)
    end

    it 'filters bulk imports created after start date' do
      expect(
        described_class.filter_created_between('2022-01-31', nil)
      ).to contain_exactly(feb_bulk_import, march_bulk_import)
    end

    it 'filters bulk imports created before end date' do
      expect(described_class.filter_created_between(nil, '2022-01-02')).to contain_exactly(jan_bulk_import)
    end
  end

  describe '#aggregate_processing_time' do
    let(:bulk_import) do
      create(:bulk_import, imports: [build(:import, :successful, duration: 60),
                                     build(:import, :successful, duration: 120)])
    end

    it 'sums the processing time of child DigitalObjectImports' do
      expect(bulk_import.aggregate_processing_time).to eq 180
    end
  end

  describe '#number_of_errors' do
    let(:failed_import) { build(:import, :failed) }
    let(:successful_import) { build(:import, :successful) }
    let(:bulk_import) { create(:bulk_import, imports: [failed_import, successful_import]) }

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

  describe '#state' do
    context 'when no imports are present' do
      let(:bulk_import) { create(:bulk_import) }

      it 'returns nil' do
        expect(bulk_import.state).to be_nil
      end
    end

    context 'when all imports are queued' do
      let(:imports) { build_list(:import, 2, :queued) }
      let(:bulk_import) { create(:bulk_import, imports: imports) }

      it 'returns queued' do
        expect(bulk_import.state).to eql BulkImport::QUEUED
      end
    end

    context 'when any imports are processing' do
      let(:processing_import) { build(:import, :processing) }
      let(:queued_import) { build(:import, :queued) }
      let(:cancelled_import) { build(:import, :cancelled) }
      let(:failed_import) { build(:import, :failed) }

      let(:bulk_import) do
        create(:bulk_import, imports: [processing_import, queued_import, cancelled_import, failed_import])
      end

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when imports are successful or queued' do
      let(:queued_import) { build(:import, :queued) }
      let(:successful_import) { build(:import, :successful) }
      let(:bulk_import) { create(:bulk_import, imports: [queued_import, successful_import]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when imports are cancelled or queued' do
      let(:queued_import) { build(:import, :queued) }
      let(:cancelled_import) { build(:import, :cancelled) }
      let(:bulk_import) { create(:bulk_import, imports: [queued_import, cancelled_import]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when all completed imports have failed but some are still running' do
      let(:failed_import) { build(:import, :failed) }
      let(:processing_import) { build(:import, :processing) }
      let(:queued_import) { build(:import, :queued) }

      let(:bulk_import) { create(:bulk_import, imports: [failed_import, processing_import, queued_import]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::IN_PROGRESS
      end
    end

    context 'when all imports are successful or cancelled' do
      let(:successful_import) { build(:import, :successful) }
      let(:cancelled_import) { build(:import, :cancelled) }

      let(:bulk_import) { create(:bulk_import, imports: [successful_import, cancelled_import]) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED
      end
    end

    context 'when all imports are successful' do
      let(:imports) { build_list(:import, 2, :successful) }
      let(:bulk_import) { create(:bulk_import, imports: imports) }

      it 'returns completed' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED
      end
    end

    context 'when all imports failed' do
      let(:imports) { build_list(:import, 2, :failed) }
      let(:bulk_import) { create(:bulk_import, imports: imports) }

      it 'returns completed' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED_WITH_ERRORS
      end
    end

    context 'when all imports are successful, failures, or cancelled' do
      let(:failed_import) { build(:import, :failed) }
      let(:successful_import) { build(:import, :successful) }

      let(:bulk_import) { create(:bulk_import, imports: [failed_import, successful_import]) }

      it 'returns completed' do
        expect(bulk_import.state).to eql BulkImport::COMPLETED_WITH_ERRORS
      end
    end

    context 'when all imports are cancelled' do
      let(:imports) { build_list(:import, 2, :cancelled) }
      let(:bulk_import) { create(:bulk_import, imports: imports) }

      it 'returns in progress' do
        expect(bulk_import.state).to eql BulkImport::CANCELLED
      end
    end
  end

  describe '#create_imports' do
    let(:bulk_import) { create(:bulk_import, csv_rows: csv_rows) }
    let(:csv_data) { Rails.root.join('spec/fixtures/imports/bulk_import_data.csv').read }
    let(:csv_rows) { StructuredCSV.parse(csv_data) }

    before do
      bulk_import.create_imports
    end

    it 'creates imports' do
      bulk_import.reload
      expect(bulk_import.imports.count).to eq(1)
      expect(bulk_import.imports.first.human_readable_name).to eq('The Mermaids Singing are Beautiful')
    end

    it 'enqueues the job' do
      bulk_import.reload
      expect(ProcessImportJob).to have_enqueued_sidekiq_job.with(bulk_import.imports.first.id)
                                                           .on("import_#{BulkImport::DEFAULT_PRIORITY}")
    end
  end
end
