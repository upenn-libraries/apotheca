# frozen_string_literal: true

module Item
  # Operation that publishes an item
  class Publish < Operation

    # Publishing Item to consumer applications. As part of the publishing process the derivatives are regenerated.
    #
    # @param id [String] item uuid
    # @param updated_by [String] email of user publishing item
    def call(id:, updated_by:)
      resource = step find_item(id)

      change_set = step create_change_set(resource: resource, updated_by: updated_by)
      step generate_derivatives(change_set)
      step publish(change_set)
      step validate(change_set)

      resource = step save(change_set)

      record_event(resource)

      resource
    end

    def publish(change_set)
      add_published_values(change_set)

      return Success(change_set) if Settings.publish.skip

      client = PublishingService::Client.new(PublishingService::Endpoint.digital_collections)
      client.publish(change_set)

      Success(change_set)
    rescue StandardError => e
      Failure(error: :error_publishing_item, exception: e, change_set: change_set)
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :publish_item, json: false)
    end

    private

    def add_published_values(change_set)
      publishing_at = DateTime.current

      change_set.first_published_at = publishing_at if change_set.first_published_at.blank?
      change_set.last_published_at = publishing_at
      change_set.published = true
    end
  end
end