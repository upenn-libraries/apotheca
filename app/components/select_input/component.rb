# frozen_string_literal: true

# Renders a select input.
module SelectInput
  class Component < ViewComponent::Base

    # @param id [String]
    # @param value [Array<String>]
    # @param field [String]
    # @param options [Array<String>] options for select
    def initialize(id:, value:, field:, options:)
      @id = id
      @values = value.empty? ? [nil] : value # adding an blank value if array is empty
      @field = field
      @options = options
    end

    def call
      select_tag(@field,
                 options_for_select(@options, selected: @value),
                 class: 'form-control', id: @id
      )
    end
  end
end