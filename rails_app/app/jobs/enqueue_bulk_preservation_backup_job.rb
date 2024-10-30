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
    query_service.find_all_of_model(model: ItemResource).flat_map do |item|
      query_service.find_many_by_ids(ids: Array.wrap(item.asset_ids)).filter_map do |asset|
        next unless asset.preservation_file_id.present? && asset.preservation_copies_ids.blank?

        [asset.id.to_s, Settings.system_user]
      end
    end
  end

  # @return [Valkyrie::MetadataAdapter]
  def query_service
    @query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
