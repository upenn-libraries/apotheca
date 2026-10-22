# frozen_string_literal: true

module Asset
  # Operation to create an Asset.
  class Create < Operation
    # Creating, validating, and persisting a new AssetResource.
    #
    # @param attributes [Hash] attributes to use when creating AssetChangeSet
    def call(attributes)
      change_set = step create_change_set(**attributes)
      step set_updated_by(change_set)
      step add_preservation_events(change_set)
      step validate(change_set)
      resource = step save(change_set)

      record_event(resource)

      resource
    end

    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :create_asset)
    end
  end
end
