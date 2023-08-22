# frozen_string_literal: true

# Job to remove an asset. Used when deleting an Item.
class RemoveAssetJob
  include Sidekiq::Job

  sidekiq_options queue: :low

  # Convert Asset ID to a Valkyrie::ID object and then use that ID to delete the asset
  # @param [String] asset_id
  def perform(asset_id)
    DeleteAsset.new.call(id: Valkyrie::ID.new(asset_id))
  end
end
