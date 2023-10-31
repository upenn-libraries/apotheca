# frozen_string_literal: true

# Job to update EZID Ark identifier with ILS metadata
class UpdateArkMetadataJob < TransactionJob
  sidekiq_options queue: :low

  def transaction(item_id)
    UpdateArkMetadata.new.call(id: item_id)
  end
end
