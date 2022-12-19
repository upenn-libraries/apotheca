# frozen_string_literal: true

module StaticFields
  module StaticField
    # Represent a single set of dt and dd(s) elements that displays a field and it's values
    class Component < ViewComponent::Base
      attr_reader :classes

      # @param [String] label
      # @param [Array] values
      # @param [Array] classes
      def initialize(label:, values: [], classes: [])
        @label = label
        @values = Array.wrap(values)
        @classes = Array.wrap(classes)
      end

      # Properly offset <dd> elements when rendering multiple <dd> values for a field
      # @param [String] value
      # @param [Integer] index
      def value_element(value:, index:)
        col_classes = index.zero? ? ['col-sm-9'] : %w[offset-sm-3 col-sm-9]
        content_tag :dd, value, class: col_classes.push(classes)
      end
    end
  end
end