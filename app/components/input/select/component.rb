# frozen_string_literal: true

module Input
  module Select
    # Renders a select input.
    class Component < ViewComponent::Base
      # @param id [String]
      # @param value [Array<String>]
      # @param field [String]
      # @param options [Array<String>] options for select
      def initialize(id:, value:, field:, options:, **args)
        @id = id
        @value = value
        @field = field
        @options = options
        @args = args
      end

      def call
        select_tag(@field,
                   options_for_select(@options, selected: @value),
                   class: 'form-control form-select-sm form-select', id: @id, **@args)
      end
    end
  end
end
