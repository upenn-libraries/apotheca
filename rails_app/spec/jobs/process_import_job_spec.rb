# frozen_string_literal: true

describe ProcessImportJob do
  context 'when performing the job' do
    let(:bulk_import) { create(:bulk_import) }
    let(:import) { create(:import, :queued, bulk_import: bulk_import) }

    it 'calls Import#process!' do
      allow(Import).to receive(:find).with(import.id) { import }
      allow(import).to receive(:process!)
      described_class.perform_inline(import.id)
      expect(import).to have_received(:process!)
    end
  end

  context 'when performing the job with cancelled state' do
    let(:bulk_import) { create(:bulk_import) }
    let(:import) { create(:import, :cancelled, bulk_import: bulk_import) }

    it 'does not call Import#process!' do
      allow(Import).to receive(:find).with(import.id) { import }
      allow(import).to receive(:process!)
      described_class.perform_inline(import.id)
      expect(import).not_to have_received(:process!)
    end
  end
end
