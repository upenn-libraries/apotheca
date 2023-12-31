# frozen_string_literal: true

# Transaction that updates an item with new attributes.
class UpdateItem
  include Dry::Transaction(container: Container)

  step :find_item, with: 'item_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'item_resource.create_change_set'
  step :set_thumbnail, with: 'item_resource.set_thumbnail'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event
  tee :enqueue_ark_metadata_update, with: 'item_resource.enqueue_ark_metadata_update'

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :update_item)
  end
end
