# frozen_string_literal: true

module Item
  # Operation that deletes an Item.
  class Delete < Operation
    # Deletes an Item. All Assets attached to the Item are enqueued for deletion.
    #
    # @param id [String] UUID of Item being updated
    # @param deleted_by [String] email of user deleting item
    def call(id:, deleted_by:)
      resource = step find_item(id)
      step unpublish_item(resource)
      step delete_derivatives(resource)
      step delete_item(resource)

      record_event(resource, deleted_by)
      delete_assets_later(resource, deleted_by)

      resource
    end

    # Unpublishing record if it's been published to an outside application
    #
    # @param resource [ItemResource]
    def unpublish_item(resource)
      if resource.published
        client = PublishingService::Client.new(PublishingService::Endpoint.digital_collections)
        client.unpublish(resource)
      end

      Success(resource)
    rescue StandardError => e
      Failure(error: :error_unpublishing_item, exception: e)
    end

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
