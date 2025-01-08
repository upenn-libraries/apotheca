# frozen_string_literal: true

# Transaction that unpublishes an Item.
class UnpublishItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'item_resource.create_change_set'
  step :unpublish
  step :save, with: 'change_set.save'
  tee :record_event

  def unpublish(change_set)
    return Success(change_set) if Settings.publish.skip

    change_set.published = false

    client = PublishingService::Client.new(**Settings.publish)
    client.unpublish(change_set)

    Success(change_set)
  rescue StandardError => e
    Failure(error: :error_unpublishing_item, exception: e, change_set: change_set)
  end

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :unpublish_item)
  end
end
