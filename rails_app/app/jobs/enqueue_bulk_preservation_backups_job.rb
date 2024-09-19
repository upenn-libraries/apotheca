# frozen_string_literal: true

# Job to backup assets to preservation storage in bulk
class EnqueueBulkPreservationBackupsJob
  include Sidekiq::Job

  def perform
    args = assets.lazy.filter_map { |a| [a.id.to_s, a.updated_by] if a.preservation_backup_needed? }.take(1_000).to_a
    PreservationBackupJob.perform_bulk(args)
  end

  private

  def assets
    Valkyrie::MetadataAdapter.find(:postgres).query_service
                             .find_all_of_model(model: AssetResource)
  end
end
