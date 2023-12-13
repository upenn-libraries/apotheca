# frozen_string_literal: true

# Transaction that deletes an asset and all of history, effectively purging it from the system. In order to purge an
# asset it cannot be linked to any item.
#
# Note: This transaction is used when an asset is being created but an error occurred.
class PurgeAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :find_parent_item, with: 'asset_resource.find_asset_parent_item'
  step :require_asset_not_attached
  step :delete_files, with: 'asset_resource.delete_files'
  step :delete_asset, with: 'asset_resource.delete_resource'
  tee :delete_events

  # Requires that the asset is not attached to an Item
  def require_asset_not_attached(item: nil, **attributes)
    return Failure(error: :asset_cannot_be_attached) if item

    Success(**attributes)
  end

  def delete_events(resource:, **_attributes)
    ResourceEvent.resource_identifier(resource.id).destroy_all
  end
end
