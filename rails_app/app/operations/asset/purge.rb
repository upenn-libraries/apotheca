# frozen_string_literal: true

module Asset
  # Operation to delete an asset and all of the history, effectively purging it from the system.
  # In order to purge an asset it cannot be linked to any item.
  #
  # Note: This operation is used to clean up when an asset is being created but an error occurred.
  class Purge < Operation
    # @param id [String] id of asset to purge
    def call(id)
      asset = step find_asset(id)
      item = step find_parent_item(asset)
      step check_for_parent_item(item)
      step delete_derivatives(asset)
      step delete_preservation_files(asset)
      step delete_resource(asset)

      delete_events(asset)
      asset
    end

    # @param item [ItemResource, nil]
    def check_for_parent_item(item)
      return Failure(error: :parent_item_found) if item

      Success()
    end

    # @param asset [AssetResource]
    def delete_events(asset)
      ResourceEvent.resource_identifier(asset.id).destroy_all
    end
  end
end
