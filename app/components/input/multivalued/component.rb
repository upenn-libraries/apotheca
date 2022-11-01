# frozen_string_literal: true

module Input
  module Multivalued
    # Renders multivalued text input with the ability to add/remove inputs.
    class Component < ViewComponent::Base
      # @param id [String]
      # @param value [Array<String>]
      # @param field [String]
      def initialize(id:, value:, field:)
        @id = id
        @values = value.empty? ? [nil] : value # adding an blank value if array is empty
        @field = field
      end
    end
  end
end
