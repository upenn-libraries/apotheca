# frozen_string_literal: true

module Item
  # Operation to detach an Asset from an Item.
  class DetachAsset < Operation
    # Detaching Asset from an Item. The asset is removed from assets_id and
    # the arranged_asset_ids.
    #
    # @param id [String] UUID of Item
    # @param asset_id [String] UUID of Asset to be removed from Item
    # @param updated_by [String] Email of User making this change
    def call(id:, asset_id:, updated_by:)
      resource = step find_item(id)
      step check_thumbnail_id(resource, asset_id)

      change_set = step create_change_set(resource: resource, updated_by: updated_by)
      step detach_asset(change_set, asset_id)
      step validate(change_set)

      resource = step save(change_set)

      record_event(resource)

      resource
    end

    # Prevent the detachment of Asset currently designated as a thumbnail with message.
    def check_thumbnail_id(resource, asset_id)
      if resource.thumbnail?(asset_id) && resource.asset_ids.count > 1
        Failure(error: :cannot_delete_thumbnail)
      else
        Success(resource: resource, asset_id: asset_id)
      end
    end

    # Removing asset_id from change_set.
    #
    # @param change_set [ItemChangeSet]
    # @param asset_id [String]
    def detach_asset(change_set, asset_id)
      # Remove asset from asset_ids and arranged_asset_ids
      change_set.asset_ids.delete asset_id
      change_set.structural_metadata.arranged_asset_ids.delete asset_id

      # Remove thumbnail if final asset is deleted.
      change_set.thumbnail_asset_id = nil if change_set.asset_ids.empty?

      Success(change_set)
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :detach_asset)
    end
  end
end
