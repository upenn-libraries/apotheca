# frozen_string_literal: true

# Transaction that publishes an item
class PublishItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'item_resource.create_change_set'
  step :generate_derivatives, with: 'item_resource.generate_derivatives'
  step :publish
  step :save, with: 'change_set.save'
  tee :record_event

  def publish(change_set)
    return Success(change_set) if Settings.publish.skip

    add_published_values(change_set)

    client = PublishingService::Client.new(PublishingService::Endpoint.colenda)
    client.publish(change_set)

    Success(change_set)
  rescue StandardError => e
    Failure(error: :error_publishing_item, exception: e, change_set: change_set)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :publish_item)
  end

  private

  def add_published_values(change_set)
    publishing_at = DateTime.current

    change_set.first_published_at = publishing_at if change_set.first_published_at.blank?
    change_set.last_published_at = publishing_at
    change_set.published = true
  end
end
