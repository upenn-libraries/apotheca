# frozen_string_literal: true

# Renders a select input.
module Input
  module Select
    class Component < ViewComponent::Base

      # @param id [String]
      # @param value [Array<String>]
      # @param field [String]
      # @param options [Array<String>] options for select
      def initialize(id:, value:, field:, options:)
        @id = id
        @value = value
        @field = field
        @options = options + [nil]
      end

      def call
        select_tag(@field,
                   options_for_select(@options, selected: @value),
                   class: 'form-control form-select-sm form-select', id: @id
        )
      end
    end
  end
end