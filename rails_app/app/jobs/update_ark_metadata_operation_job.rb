# frozen_string_literal: true

# Job to update EZID Ark identifier with an Item's metadata.
class UpdateArkMetadataOperationJob < OperationJob
  sidekiq_options queue: :low

  def operation(item_id)
    Item::UpdateArkMetadata.new.call(item_id)
  end
end
