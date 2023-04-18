# frozen_string_literal: true

require_relative 'concerns/queueable'

describe Import do
  it_behaves_like 'queueable'

  it 'requires a BulkImport' do
    import = build :import, bulk_import: nil
    expect(import.valid?).to be false
    expect(import.errors['bulk_import']).to include 'must exist'
  end

  it 'requires import data' do
    import = build :import, import_data: nil
    expect(import.valid?).to be false
    expect(import.errors['import_data']).to include "can't be blank"
  end

  it 'creates an import' do
    import = create :import
    expect(import.valid?).to be true
    expect(import.import_data).to be_a Hash
  end

  describe '#process!' do
    include_context 'with successful requests to mint EZID'
    include_context 'with successful requests to update EZID'

    let(:bulk_import) { create(:bulk_import) }
    let(:import) { create(:import, :queued, bulk_import: bulk_import) }

    it 'calls #run' do
      allow(import).to receive(:run).and_call_original
      import.process!
      expect(import).to have_received(:run)
    end
  end

  describe '#run' do
    include_context 'with successful requests to mint EZID'
    include_context 'with successful requests to update EZID'

    let(:bulk_import) { create(:bulk_import) }
    let(:import) { create(:import, :processing, bulk_import: bulk_import) }
    let(:invalid_import) { create(:import, :processing, :with_no_assets, bulk_import: bulk_import) }

    context 'when Success monad is returned' do
      before do
        import.run
      end

      it 'is successful' do
        expect(import.state).to eq described_class::STATE_SUCCESSFUL.to_s
      end

      it 'calculates and stores duration' do
        expect(import.duration).not_to be_nil
      end

      it 'sets resource identifier' do
        expect(import.resource_identifier).not_to be_nil
      end
    end

    context 'when Failure monad is returned' do
      before do
        invalid_import.run
      end

      it 'is not successful' do
        expect(invalid_import.state).to eq described_class::STATE_FAILED.to_s
      end

      it 'adds Failure monad information to process_errors' do
        expect(invalid_import.process_errors).to eq ['assets must be provided to create an object']
      end
    end
  end
end
