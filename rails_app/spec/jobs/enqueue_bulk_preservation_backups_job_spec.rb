# frozen_string_literal: true

describe EnqueueBulkPreservationBackupsJob do
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

  context 'with assets with associated items' do
    let!(:additional_asset_to_backup) do
      persist(:asset_resource, :with_preservation_file, preservation_copies_ids: nil)
    end

    before do
      persist(:item_resource, :with_asset, asset: with_preservation_backup)
      persist(:item_resource, :with_asset, asset: without_preservation_backup)
      persist(:item_resource, :with_asset, asset: additional_asset_to_backup)
    end

    it 'enqueues jobs for assets without a preservation backup' do
      expect { job.perform_inline }.to enqueue_sidekiq_job(PreservationBackupJob)
        .with(without_preservation_backup.id.to_s, without_preservation_backup.updated_by)
      expect { job.perform_inline }.to enqueue_sidekiq_job(PreservationBackupJob)
        .with(additional_asset_to_backup.id.to_s, additional_asset_to_backup.updated_by)
    end

    it 'does not enqueue jobs for assets with preservation backup' do
      expect { job.perform_inline }.not_to enqueue_sidekiq_job(PreservationBackupJob)
        .with(with_preservation_backup.id.to_s, with_preservation_backup.updated_by)
    end
  end
end
