# frozen_string_literal: true

# Enqueue Bulk Refresh ILS Metadata Job for all ItemResources with bibnumbers
class EnqueueBulkRefreshIlsMetadataJob
  include Sidekiq::Job

  sidekiq_options queue: :high

  def perform(email)
    args = bulk_args(email).compact_blank.to_a
    RefreshIlsMetadataJob.set(queue: :low).perform_bulk(args)
  end

  private

  # Retrieve lazily evaluated collection of iterm args for **all** items
  # with a bibnumber
  #
  # @return [Enumerator::Lazy]
  def bulk_args(email)
    query_service.custom_queries
                 .items_with_bibnumber
                 .map { |item| [item.id.to_s, email] }
  end

  def query_service
    @query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
