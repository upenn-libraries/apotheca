# frozen_string_literal: true

module Item
  # Operation to unpublish an item
  class Unpublish < Operation
    # Unpublishing item from consumer applications.
    #
    # @param id [String] item uuid
    # @param updated_by [String] email of user publishing item
    def call(id, updated_by)
      resource = step find_item(id)
      change_set = step create_change_set(resource: resource, updated_by: updated_by)
      step unpublish(change_set)
      step validate(change_set)
      resource = step save(change_set)

      record_event(resource)

      resource
    end

    # @param change_set [ItemChangeSet]
    def unpublish(change_set)
      return Success(change_set) if Settings.publish.skip

      change_set.published = false

      client = PublishingService::Client.new(PublishingService::Endpoint.digital_collections)
      client.unpublish(change_set)

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_unpublishing_item, exception: e, change_set: change_set)
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :unpublish_item, json: false)
    end
  end
end
