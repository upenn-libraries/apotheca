# frozen_string_literal: true

describe GenerateReportJob do
  let(:report) { create(:report, :queued) }

  before { allow(Report).to receive(:create!).and_return(report) }

  context 'when performing the job later' do
    it 'enqueues the job' do
      described_class.perform_async(report.report_type)
      expect(described_class).to have_enqueued_sidekiq_job.with(report.report_type)
    end
  end

  context 'when performing the job' do
    it 'calls Report#process!' do
      allow(report).to receive(:process!)
      described_class.perform_inline(report.report_type)
      expect(report).to have_received(:process!)
    end

    it 'generates a file' do
      expect(report.file).not_to be_attached
      described_class.perform_inline(report.report_type)
      expect(report.file).to be_attached
    end
  end
end
