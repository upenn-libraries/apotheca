# frozen_string_literal: true

# Job to refresh ILS metadata
class RefreshIlsMetadataJob < TransactionJob
  sidekiq_options queue: :high

  def transaction(item_id)
    RefreshIlsMetadata.new.call(id: item_id)
  end
end
