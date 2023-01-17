# frozen_string_literal: true

# Job to remove all assets. Used when deleting an Item.
class RemoveAllAssetsJob < ApplicationJob
  # Convert Asset ID to a Valkyrie::ID object and then use that ID to delete the asset
  # @param [Array<String>] asset_ids
  def perform(asset_ids)
    asset_ids.each do |asset_id|
      DeleteAsset.new.call(id: Valkyrie::ID.new(asset_id))
    end
  end
end
