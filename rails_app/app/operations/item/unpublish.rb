# frozen_string_literal: true

module Item
  # Operation to unpublish an item
  class Unpublish < Operation
    UNPUBLISH = 'unpublish'

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
      connection = step publishing_connection(PublishingService::Endpoint.digital_collections)
      step unpublish(change_set, connection)
      step validate(change_set)
      resource = step save(change_set)

      record_event(resource)

      resource
    end

    # @param change_set [ItemChangeSet]
    # @param connection [Faraday::Connection]
    def unpublish(change_set, connection)
      return Success(change_set) if Settings.publish.skip

      change_set.published = false

      post_request(change_set, connection)

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_unpublishing_item, exception: e, change_set: change_set)
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :unpublish_item, json: false)
    end

    private

    # @param change_set [ItemChangeSet, ItemResource]
    # @param connection [Faraday::Connection]
    def post_request(change_set, connection)
      connection.post(@endpoint.webhook_path, { event: UNPUBLISH, data: { item: { id: change_set.id.to_s } } })
    rescue Faraday::ResourceNotFound
      # Not raising error when attempting to unpublish an item that hasn't been published.
    rescue Faraday::ClientError, Faraday::ServerError => e
      message = e.response_body&.dig('message') || e.msg
      raise Error, "Request to publishing endpoint failed: #{message}"
    end
  end
end
