# frozen_string_literal: true

module Steps
  # Required that updated_by attribute is provided.
  class RequireAttribute
    include Dry::Monads[:result]

    attr_reader :required_attribute

    def initialize(required_attribute)
      @required_attribute = required_attribute
    end

    def call(attributes)
      if attributes[required_attribute].blank?
        Failure(error: "missing_#{required_attribute}".to_sym)
      else
        Success(attributes)
      end
    end
  end
end
