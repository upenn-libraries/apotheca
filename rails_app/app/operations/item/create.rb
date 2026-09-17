# frozen_string_literal: true

module Item
  # Operation to create an Item.
  class Create < Operation
    # Creating, validating and persisting a new ItemResource.
    #
    # @param attributes [Hash] attributes to use when creating ItemChangeSet
    def call(attributes)
      change_set = step create_change_set(**attributes)
      step set_ark(change_set)
      step set_thumbnail(change_set)
      step set_updated_by(change_set)
      step validate(change_set)
      resource = step save(change_set)

      enqueue_ark_metadata_update(resource)
      record_event(resource)

      resource
    end

    def set_ark(change_set)
      if change_set.unique_identifier.blank?
        ark = Ezid::Identifier.mint.to_s
        change_set.unique_identifier = ark
      end

      Success(change_set)
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :create_item)
    end
  end
end
