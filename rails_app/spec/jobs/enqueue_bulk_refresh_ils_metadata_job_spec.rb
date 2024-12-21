# frozen_string_literal: true

describe EnqueueBulkRefreshIlsMetadataJob do
  let(:job) { described_class }

  before { 2.times { persist(:item_resource) } }

  context 'when there are no items with bibnumbers' do
    it 'does not enqueue an ILS refresh job' do
      expect { job.perform_inline }.not_to enqueue_sidekiq_job(RefreshIlsMetadataJob)
    end
  end

  context 'when there is at least one item with a bibnumber' do
    include_context 'with successful Marmite request' do
      let(:xml) { File.read(file_fixture('marmite/marc_xml/book-1.xml')) }
    end

    let!(:first_item_with_bib) { persist(:item_resource, :with_bibnumber) }
    let!(:second_item_with_bib) { persist(:item_resource, :with_bibnumber) }

    it 'enqueues an ILS refresh job' do
      expect { job.perform_inline }.to enqueue_sidekiq_job(RefreshIlsMetadataJob)
      expect(RefreshIlsMetadataJob.jobs.size).to eq 2
    end

    it 'enqueues an ILS refresh job with the correct arguments' do
      expect { job.perform_inline }.to enqueue_sidekiq_job(RefreshIlsMetadataJob)
        .with(first_item_with_bib.id.to_s, Settings.system_user)
      expect { job.perform_inline }.to enqueue_sidekiq_job(RefreshIlsMetadataJob)
        .with(second_item_with_bib.id.to_s, Settings.system_user)
    end
  end
end
