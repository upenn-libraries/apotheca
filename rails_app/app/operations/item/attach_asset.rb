# frozen_string_literal: true

module Item
  # Operation to add an Asset to an Item.
  class AttachAsset < Operation
    # Adds an Asset to an Item. The asset is only added to the asset_id array, it is not
    # ordered in the structural metadata.
    #
    # @param id [String] UUID of Item being updated
    # @param updated_by [String] email of user updating the item
    # @param asset_id [String] UUID of Asset being added to Item
    def call(id:, updated_by:, asset_id:)
      resource = step find_item(id)

      change_set = step create_change_set(resource: resource, updated_by: updated_by)
      step add_asset(change_set, asset_id)
      step set_thumbnail(change_set)
      step validate(change_set)

      resource = step save(change_set)

      record_event(resource)

      resource
    end

    # Adding asset_id to list of asset_ids within item.
    def add_asset(change_set, asset_id)
      change_set.asset_ids = (change_set.asset_ids || []).append(asset_id)

      Success(change_set)
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :attach_asset)
    end
  end
end
