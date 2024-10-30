# frozen_string_literal: true

describe EnqueueBulkPreservationBackupJob do
  let!(:with_preservation_backup) { persist(:asset_resource, :with_preservation_file, :with_preservation_backup) }
  let!(:without_preservation_backup) do
    persist(:asset_resource, :with_preservation_file, preservation_copies_ids: nil)
  end
  let(:job) { described_class }

  context 'with assets without associated items' do
    it 'does not enqueue preservation backup jobs' do
      expect { job.perform_inline }.not_to enqueue_sidekiq_job(PreservationBackupJob)
    end
  end

  context 'with items with no assets' do
    before { persist(:item_resource) }

    it 'does not enqueue preservation backup jobs' do
      expect { job.perform_inline }.not_to enqueue_sidekiq_job(PreservationBackupJob)
    end
  end

  context 'with items with backed up assets' do
    before { persist(:item_resource, :with_asset, asset: with_preservation_backup) }

    it 'does not enqueue preservation backup jobs' do
      expect { job.perform_inline }.not_to enqueue_sidekiq_job(PreservationBackupJob)
    end
  end

  context 'with items without backed up assets' do
    let!(:additional_asset_to_backup) do
      persist(:asset_resource, :with_preservation_file, preservation_copies_ids: nil)
    end

    before do
      persist(:item_resource, :with_asset, asset: without_preservation_backup)
      persist(:item_resource, :with_asset, asset: additional_asset_to_backup)
    end

    it 'enqueues the expected jobs' do
      expect { job.perform_inline }.to enqueue_sidekiq_job(PreservationBackupJob)
      expect(PreservationBackupJob.jobs.size).to eq 2
    end

    it 'enqueues the expected jobs with the correct arguments' do
      expect { job.perform_inline }.to enqueue_sidekiq_job(PreservationBackupJob)
        .with(without_preservation_backup.id.to_s, Settings.system_user)
      expect { job.perform_inline }.to enqueue_sidekiq_job(PreservationBackupJob)
        .with(additional_asset_to_backup.id.to_s, Settings.system_user)
    end

    context 'when receiving a batch size parameter' do
      it 'enqueues the expected number of jobs' do
        expect { job.perform_inline(1) }.to enqueue_sidekiq_job(PreservationBackupJob)
        expect(PreservationBackupJob.jobs.size).to eq 1
      end
    end
  end
end
