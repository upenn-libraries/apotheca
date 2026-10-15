# frozen_string_literal: true

module Asset
  # Parent class for Asset Operations. Includes reuseable steps for Asset operations.
  class Operation < Resource::Operation
    alias_method :find_asset, :find_resource

    def resource_class
      AssetResource
    end

    def change_set_class
      AssetChangeSet
    end

    def derivative_generator_class
      DerivativeService::Asset::Derivatives
    end

    def derivative_types
      AssetResource::DERIVATIVE_TYPES
    end

    def add_preservation_events(*args)
      Steps::AddPreservationEvents.new.call(*args)
    end

    def virus_check(*args)
      Steps::VirusCheck.new.call(*args)
    end

    def add_technical_metadata(*args)
      Steps::AddTechnicalMetadata.new.call(*args)
    end
  end
end
