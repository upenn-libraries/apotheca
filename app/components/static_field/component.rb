# frozen_string_literal: true

# Renders a select input.
module StaticField
  # component for a static field used in show pages
  class Component < ViewComponent::Base

    # @param label [String]
    # @param value [String, Array<String>]
    def initialize(label:, value:)
      @label = label.to_s.titlecase
      @id = label.to_s.downcase.tr(' ', '-')
      @value = value
    end
  end
end
