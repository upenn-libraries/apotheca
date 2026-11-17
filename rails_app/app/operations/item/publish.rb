# frozen_string_literal: true

module Item
  # Operation that publishes an item
  class Publish < Operation
    PUBLISH = 'publish'

    # @param endpoint [PublishingEndpoint]
    def initialize(endpoint = PublishingEndpoint.digital_collections)
      @endpoint = endpoint
    end

    # Publishing Item to consumer applications. As part of the publishing process the derivatives are regenerated.
    #
    # @param id [String] item uuid
    # @param updated_by [String] email of user publishing item
    def call(id, updated_by)
      resource = step find_item(id)

      change_set = step create_change_set(resource: resource, updated_by: updated_by)
      step generate_derivatives(change_set)
      step publish(change_set)
      step validate(change_set)

      resource = step save(change_set)

      record_event(resource)

      resource
    end

    # @param change_set [ItemChangeSet]
    def publish(change_set)
      add_published_values(change_set)

      return Success(change_set) if Settings.publish.skip

      send_publish_request(change_set)

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_publishing_item, exception: e, change_set: change_set)
    end

    # @param resource [ItemResource]
    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :publish_item, json: false)
    end

    private

    # @param change_set [ItemChangeSet]
    def add_published_values(change_set)
      publishing_at = DateTime.current

      change_set.first_published_at = publishing_at if change_set.first_published_at.blank?
      change_set.last_published_at = publishing_at
      change_set.published = true
    end

    # @param change_set [ItemChangeSet]
    def serialize(change_set)
      controller = ApplicationController.renderer.with_defaults(http_host: Settings.api_url, https: true)
      rendered_json = controller.render('api/resources/items/_item',
                                        locals: { params: { assets: 'true' } },
                                        assigns: { item: change_set.presenter })
      JSON.parse(rendered_json)
    end

    # @param change_set [ItemChangeSet, ItemResource]
    def send_publish_request(change_set)
      publishing_connection(@endpoint)
        .post(@endpoint.webhook_path, { event: PUBLISH, data: { item: serialize(change_set) } })
    rescue Faraday::ClientError, Faraday::ServerError => e # Raising error if publishing request failed
      message = e.response_body&.dig('message') || e.msg
      raise Error, "Request to publishing endpoint failed: #{message}"
    end
  end
end
