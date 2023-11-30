# frozen_string_literal: true

# Job to remove an asset. Used when deleting an Item.
class RemoveAssetJob < TransactionJob
  sidekiq_options queue: :low

  # Convert Asset ID to a Valkyrie::ID object and then use that ID to delete the asset
  # @param [String] asset_id
  def transaction(asset_id, deleted_by)
    DeleteAsset.new.call(id: Valkyrie::ID.new(asset_id), deleted_by: deleted_by)
  end
end
