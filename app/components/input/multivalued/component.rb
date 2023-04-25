# frozen_string_literal: true

module Input
  module Multivalued
    # Renders multivalued text input with the ability to add/remove inputs.
    class Component < ViewComponent::Base
      # @param value [Array<String>]
      # @param field [String]
      # @param options [Hash]
      def initialize(value:, field:, **options)
        @values = value.empty? ? [nil] : value # adding an blank value if array is empty
        @field = field
        @options = options
      end

      def input_for(value)
        text_field_tag @field, value, **@options
      end
    end
  end
end
