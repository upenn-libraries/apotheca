# frozen_string_literal: true

describe ProcessBulkExportJob do
  context 'when performing the job later' do
    let(:bulk_export) { create(:bulk_export, :queued) }

    it 'enqueues the job' do
      described_class.perform_async(bulk_export.id)
      expect(described_class).to have_enqueued_sidekiq_job.with(bulk_export.id)
    end
  end

  context 'when performing the job' do
    let(:bulk_export) { create(:bulk_export, :queued) }

    before { persist(:item_resource) }

    it 'calls BulkExport#process!' do
      allow(BulkExport).to receive(:find).with(bulk_export.id) { bulk_export }
      allow(bulk_export).to receive(:process!)
      described_class.perform_inline(bulk_export.id)
      expect(bulk_export).to have_received(:process!)
    end

    it 'generates a CSV' do
      allow(BulkExport).to receive(:find).with(bulk_export.id) { bulk_export }
      expect(bulk_export.csv).not_to be_attached
      described_class.perform_inline(bulk_export.id)
      expect(bulk_export.csv).to be_attached
    end
  end

  context 'when performing the job with cancelled state' do
    let(:bulk_export) { create(:bulk_export, :cancelled) }

    it 'does not call BulkExport#process!' do
      allow(BulkExport).to receive(:find).with(bulk_export.id) { bulk_export }
      allow(bulk_export).to receive(:process!)
      described_class.perform_inline(bulk_export.id)
      expect(bulk_export).not_to have_received(:process!)
    end
  end
end
