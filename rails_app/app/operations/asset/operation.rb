# frozen_string_literal: true

module Asset
  # Parent class for Asset Operations. Includes reuseable steps for Asset operations.
  class Operation < Resource::Operation
    alias find_asset find_resource

    def resource_class
      AssetResource
    end

    def change_set_class
      AssetChangeSet
    end

    def add_preservation_events(*args)
      Steps::AddPreservationEvents.new.call(*args)
    end
  end
end
