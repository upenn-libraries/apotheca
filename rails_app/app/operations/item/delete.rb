# frozen_string_literal: true

module Item
  # Operation that deletes an Item.
  class Delete < Operation
    # Deletes an Item. All Assets attached to the Item are enqueued for deletion.
    #
    # @param id [String] UUID of Item being updated
    # @param deleted_by [String] email of user deleting item
    def call(id, deleted_by)
      resource = step find_item(id)
      step send_unpublish_request(resource) if resource.published
      step delete_derivatives(resource)
      step delete_item(resource)

      record_event(resource, deleted_by)
      delete_assets_later(resource, deleted_by)

      resource
    end

    # @param resource [ItemResource]
    # @param deleted_by [String]
    def record_event(resource, deleted_by)
      ResourceEvent.record_event_for(resource: resource, event_type: :delete_item, json: false,
                                     initiated_by: deleted_by)
    end

    # An Item can have lots of Assets, so we enqueue jobs to delete each of them here.
    #
    # @param resource [ItemResource]
    # @param deleted_by [String]
    def delete_assets_later(resource, deleted_by)
      asset_params = resource.asset_ids&.map { |id| [id.to_s, deleted_by] }
      return if asset_params.blank?

      DeleteAssetJob.perform_bulk(asset_params)
    end
  end
end
