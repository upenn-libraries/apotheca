# frozen_string_literal: true

module Asset
  module Steps
    include Resource::Steps

    def find_asset(id)
      Resource::Steps::FindResource.new(AssetResource).call(id)
    end

    def create_change_set(attributes)
      resource = attributes.delete(:resource) || AssetResource.new
      change_set = AssetChangeSet.new(resource)

      begin
        change_set.validate(attributes)
        Success(change_set)
      rescue StandardError => e
        Failure(error: :error_creating_change_set, exception: e)
      end
    end

    def virus_check(*args)
      VirusCheck.new.call(*args)
    end

    def add_preservation_events(*args)
      AddPreservationEvents.new.call(*args)
    end

    def add_technical_metadata(*args)
      AddTechnicalMetadata.new.call(*args)
    end

    def generate_derivatives(*args)
      Steps::GenerateDerivatives.new(DerivativeService::Asset::Derivatives,
                                     AssetResource::DERIVATIVE_TYPES).call(*args)
    end
  end
end
