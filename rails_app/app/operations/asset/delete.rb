# frozen_string_literal: true

module Asset
  # Operation to delete an asset, but keep its history.
  class Delete < Asset::Operation
    # @param id [String]
    # @param deleted_by [String]
    def call(id, deleted_by)
      asset = step find_asset(id)
      item = step find_parent_item(asset)
      step detach_from_item(id: item.id, asset_id: asset.id, updated_by: deleted_by) if item
      step delete_derivatives(asset)
      step delete_preservation_files(asset)
      step delete_resource(asset)

      record_event(asset, deleted_by)

      asset
    end

    # @param resource [AssetResource]
    # @param deleted_by [String]
    def record_event(resource, deleted_by)
      ResourceEvent.record_event_for(resource: resource, event_type: :delete_asset, json: false,
                                     initiated_by: deleted_by)
    end
  end
end
