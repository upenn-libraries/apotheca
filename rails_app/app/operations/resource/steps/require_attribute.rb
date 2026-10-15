# frozen_string_literal: true

module Resource
  module Steps
    # Checks that required attribute is provided.
    class RequireAttribute
      include Dry::Monads[:result]

      attr_reader :required_attribute

      # @param required_attribute [Symbol]
      def initialize(required_attribute)
        @required_attribute = required_attribute
      end

      # Checks that the required_attribute is present in the Hash.
      #
      # @param attributes [Hash]
      def call(attributes)
        if attributes[required_attribute].blank?
          Failure(error: "missing_#{required_attribute}".to_sym)
        else
          Success(attributes)
        end
      end
    end
  end
end
