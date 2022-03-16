# frozen_string_literal: true

module MultivaluedInput
  class Component < ViewComponent::Base
    # TODO: Make this class more general so that it can also be used with single valued fields, we may
    #       need to rename this component.
    def initialize(label:, value:, field:)
      @label = label.to_s.titlecase
      @id = label.to_s.downcase.tr(' ', '-')
      @values = value.empty? ? [nil] : value # this value should be an array; adding an blank value if array is empty
      @field = field
    end
  end
end