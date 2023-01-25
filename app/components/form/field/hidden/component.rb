# frozen_string_literal: true

module Form
  module Field
    module Hidden
      # Component for hidden input.
      class Component < ViewComponent::Base
        def initialize(field:, value:, **options)
          @field = field
          @value = value
          @options = options
        end

        def call
          hidden_field_tag @field, @value, **@options
        end
      end
    end
  end
end
