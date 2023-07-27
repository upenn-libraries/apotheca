# frozen_string_literal: true

module ItemDescriptiveMetadata
  class Component < ViewComponent::Base
    def initialize(descriptive_metadata_presenter:)
      @descriptive_metadata_presenter = descriptive_metadata_presenter
    end
  end
end

