# frozen_string_literal: true

module Item
  # Operation to update an Item.
  class Update < Operation
    # Operation that updates an Item with new attributes.
    #
    # @param id [String] UUID of Item being updated
    # @param attributes [Hash] Item attributes to set when updating
    def call(id:, **attributes)
      resource = step find_item(id)
      step require_updated_by(attributes)

      change_set = step create_change_set(resource: resource, **attributes)
      step set_thumbnail(change_set)
      step validate(change_set)

      resource = step save(change_set)

      record_event(resource)
      update_ark_metadata_later(resource)

      resource
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :update_item)
    end
  end
end
