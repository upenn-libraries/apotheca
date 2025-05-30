# frozen_string_literal: true

require_relative 'concerns/queueable'

describe Import do
  it_behaves_like 'queueable'

  it 'requires a BulkImport' do
    import = build(:import, bulk_import: nil)
    expect(import.valid?).to be false
    expect(import.errors['bulk_import']).to include 'must exist'
  end

  it 'requires import data' do
    import = build(:import, import_data: nil)
    expect(import.valid?).to be false
    expect(import.errors['import_data']).to include "can't be blank"
  end

  it 'creates an import' do
    import = create(:import)
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

    context 'when Success monad is returned' do
      let(:import) { create(:import, :processing, bulk_import: bulk_import) }

      before { import.run }

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
      let(:import) { create(:import, :processing, :with_no_assets, bulk_import: bulk_import) }

      before { import.run }

      it 'is not successful' do
        expect(import.state).to eq described_class::STATE_FAILED.to_s
      end

      it 'calculates and stores duration' do
        expect(import.duration).not_to be_nil
      end

      it 'adds Failure monad information to process_errors' do
        expect(import.process_errors).to contain_exactly('assets must be provided to create an object',
                                                         'asset storage and path must be provided')
      end
    end

    context 'when Failure monad is returned without error details' do
      before do
        import_service = instance_double(ImportService::Process::Create)
        allow(ImportService::Process::Create).to receive(:new).and_return(import_service)
        allow(import_service).to receive(:run).and_return(
          Dry::Monads::Failure.new(error: :error_generating_derivatives, exception: StandardError.new('Random Error'))
        )

        import.run
      end

      let(:import) { create(:import, :processing, bulk_import: bulk_import) }

      it 'is not successful' do
        expect(import.state).to eq described_class::STATE_FAILED.to_s
      end

      it 'adds Failure monad information to process_errors' do
        expect(import.process_errors).to contain_exactly('Random Error')
      end
    end
  end

  describe '#human_readable_name' do
    let(:bulk_import) { create(:bulk_import) }

    context 'when an item is associated' do
      let(:import) { create(:import, bulk_import: bulk_import, resource_identifier: 'test_id') }

      it 'returns name from associated item' do
        persist(:item_resource, unique_identifier: 'test_id')
        expect(import.human_readable_name).to eq('New Item')
      end
    end

    context 'when no item is associated' do
      let(:import) { create(:import, bulk_import: bulk_import) }

      it 'returns name from import_data when item not present' do
        expect(import.human_readable_name).to eq('Marian Anderson; SSID: 18792434; filename: 10-14-1.tif')
      end
    end
  end

  describe '#resource' do
    let(:bulk_import) { create(:bulk_import) }

    context 'when an item is associated' do
      let(:item_resource) { persist(:item_resource, unique_identifier: 'test_id') }
      let(:import) { create(:import, bulk_import: bulk_import, resource_identifier: item_resource.unique_identifier) }

      it 'returns the resource' do
        expect(import.resource).to be_an ItemResource
        expect(import.resource.id).to eq(item_resource.id)
      end
    end

    context 'when no item is associated' do
      let(:import) { create(:import, bulk_import: bulk_import) }

      it 'returns nil' do
        expect(import.resource).to be_nil
      end
    end
  end
end
