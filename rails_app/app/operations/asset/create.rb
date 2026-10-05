# frozen_string_literal: true

# Transaction that creates an asset with the given attributes.
module Asset
  class Create < Dry::Operation
    include Steps

    def call(attributes)
      change_set = step create_change_set(attributes)
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
