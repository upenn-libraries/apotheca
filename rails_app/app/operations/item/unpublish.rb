# frozen_string_literal: true

module Item
  # Operation to unpublish an item
  class Unpublish < Operation
    # @param endpoint [PublishingEndpoint]
    def initialize(endpoint = PublishingEndpoint.digital_collections)
      @endpoint = endpoint
    end

    # Unpublishing item from consumer applications.
    #
    # @param id [String] item uuid
    # @param updated_by [String] email of user publishing item
    def call(id, updated_by)
      resource = step find_item(id)
      change_set = step create_change_set(resource: resource, updated_by: updated_by)
      step unpublish(change_set) unless Settings.publish.skip
      step validate(change_set)
      resource = step save(change_set)

      record_event(resource)

      resource
    end

    # @param change_set [ItemChangeSet]
    def unpublish(change_set)
      change_set.published = false
      send_unpublish_request(change_set, @endpoint)
    rescue StandardError => e
      Failure(error: :error_unpublishing_item, exception: e)
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :unpublish_item, json: false)
    end
  end
end
