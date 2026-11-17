# frozen_string_literal: true

# Job to remove an asset. Used when deleting an Item.
class DeleteAssetJob < OperationJob
  sidekiq_options queue: :low

  # Convert Asset ID to a Valkyrie::ID object and then use that ID to delete the asset
  # @param asset_id [Valkyrie::ID, String]
  # @param deleted_by [String]
  def operation(asset_id, deleted_by)
    Asset::Delete.new.call(Valkyrie::ID.new(asset_id), deleted_by)
  end
end
