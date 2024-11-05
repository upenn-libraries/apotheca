# frozen_string_literal: true

# Job to backup assets to preservation storage in bulk
class EnqueueBulkPreservationBackupJob
  include Sidekiq::Job

  sidekiq_options queue: :medium

  DEFAULT_BATCH_SIZE = 1_000

  def perform(batch_size = DEFAULT_BATCH_SIZE)
    args = bulk_args.compact_blank.take(batch_size).to_a
    PreservationBackupJob.perform_bulk(args)
  end

  private

  # Retrieve lazily evaluated collection of asset args from all items
  # @return [Enumerator::Lazy]
  def bulk_args
    query_service.custom_queries
                 .missing_preservation_backup
                 .map { |asset| [asset.id.to_s, Settings.system_user] }
  end

  # @return [Valkyrie::MetadataAdapter]
  def query_service
    @query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
