# frozen_string_literal: true
module Form
  module Field
    module Input
      module Select
        # Renders a select input.
        class Component < ViewComponent::Base
          # @param value [Array<String>]
          # @param field [String]
          # @param choices [Array<String>] options for select
          def initialize(value:, field:, choices:, **options)
            @value = value
            @field = field
            @choices = choices
            @options = options
          end

          def call
            select_tag(@field,
                       options_for_select(@choices, selected: @value),
                       class: 'form-control form-select-sm form-select', **@options)
          end
        end
      end
    end
  end
end

