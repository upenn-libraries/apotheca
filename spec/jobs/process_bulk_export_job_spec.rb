# frozen_string_literal: true

describe ProcessBulkExportJob, type: :job do

  context 'when performing the job later' do
    let(:bulk_export) { create(:bulk_export, state: BulkExport::STATE_QUEUED) }

    it 'enqueues the job' do
      described_class.perform_later(bulk_export)
      expect(described_class).to have_been_enqueued.with(bulk_export)
    end
  end

  context 'when performing the job' do

    let(:bulk_export) { create(:bulk_export, state: BulkExport::STATE_QUEUED) }
    let!(:item) { persist(:item_resource) }

    it 'calls BulkExport#process!' do

      allow(bulk_export).to receive(:process!)
      described_class.perform_now(bulk_export)
      expect(bulk_export).to have_received(:process!)
    end

    it 'generates a CSV' do
      expect(bulk_export.csv).not_to be_attached
      described_class.perform_now(bulk_export)
      expect(bulk_export.csv).to be_attached
    end
  end

  context 'when performing the job with cancelled state' do
    let(:bulk_export) { create(:bulk_export, state: BulkExport::STATE_CANCELLED) }

    it 'does not call BulkExport#process!' do
      allow(bulk_export).to receive(:process!)
      described_class.perform_now(bulk_export)
      expect(bulk_export).not_to have_received(:process!)
    end

    it 'returns nil' do
      expect(described_class.perform_now(bulk_export)).to be_nil
    end
  end
end
