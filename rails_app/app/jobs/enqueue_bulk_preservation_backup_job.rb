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
        [asset.id.to_s, system_email] if asset.preservation_file_id.present? && asset.preservation_copies_ids.blank?
      end
    end
  end

  # Return system email to use as the updated_by user.
  def system_email
    I18n.t('system_email')
  end

  # @return [Valkyrie::MetadataAdapter]
  def query_service
    @query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
