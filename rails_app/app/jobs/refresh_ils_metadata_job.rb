# frozen_string_literal: true

# Job to refresh ILS metadata
class RefreshIlsMetadataJob < TransactionJob
  sidekiq_options queue: :high

  def transaction(item_id, updated_by)
    RefreshIlsMetadata.new.call(id: item_id, updated_by: updated_by)
  end
end
