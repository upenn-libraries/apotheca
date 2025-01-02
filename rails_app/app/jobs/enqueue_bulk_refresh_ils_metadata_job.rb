# frozen_string_literal: true

# Enqueue Bulk Refresh ILS Metadata Job for all ItemResources with bibnumbers
class EnqueueBulkRefreshIlsMetadataJob
  include Sidekiq::Job

  sidekiq_options queue: :low

  DEFAULT_BATCH_SIZE = 1_000 # The sidekiq perform_bulk default

  def perform(batch_size = DEFAULT_BATCH_SIZE)
    args = bulk_args.compact_blank.to_a
    RefreshIlsMetadataJob.perform_bulk(args, batch_size: batch_size)
  end

  private

  # Retrieve lazily evaluated collection of iterm args for **all** items
  # with a bibnumber
  #
  # @return [Enumerator::Lazy]
  def bulk_args
    query_service.custom_queries
                 .items_with_bibnumber
                 .map { |asset| [asset.id.to_s, Settings.system_user] }
  end

  def query_service
    @query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
