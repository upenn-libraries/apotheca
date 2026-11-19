# frozen_string_literal: true

# Job to update EZID Ark identifier with an Item's metadata.
class UpdateArkMetadataJob < OperationJob
  sidekiq_options queue: :low

  def operation(item_id)
    Item::UpdateArkMetadata.call(item_id)
  end
end
