# frozen_string_literal: true

describe DeleteOldBulkImportsJob do
  let(:report) { create(:report, :queued) }

  before { allow(Report).to receive(:create!).and_return(report) }

  context 'when has bulk imports older than 6 months' do
    before do
      create_list(:bulk_import, 2, updated_at: 7.months.ago)
      create_list(:bulk_import, 1)
    end

    it 'deletes old bulk imports' do
      expect(BulkImport.count).to be 3
      described_class.perform_inline
      expect(BulkImport.count).to be 1
    end
  end

  context 'when has bulk imports from the last 6 months' do
    before do
      create_list(:bulk_import, 2)
    end

    it 'does not delete bulk imports' do
      described_class.perform_inline
      expect(BulkImport.count).to be 2
    end
  end
end
