# frozen_string_literal: true

module StaticFields
  # Show a set of metadata fields in a description list element.
  class Component < ViewComponent::Base
    renders_many :fields, StaticField::Component

    def initialize(**options)
      @options = options
    end

    def render?
      fields.any?
    end

    def call
      render(RowComponent.new(:dl, **@options)) do
        safe_join(fields)
      end
    end
  end
end
