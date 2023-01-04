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
          def initialize(value:, field:, choices:, size: nil, **options)
            @value = value
            @field = field
            @choices = choices
            @options = options

            @options[:class] = Array.wrap(@options[:class]).append('form-select')
            @options[:class] = @options[:class].append("form-select-#{size}") if size
          end

          def call
            select_tag(@field, options_for_select(@choices, selected: @value), **@options)
          end
        end
      end
    end
  end
end

