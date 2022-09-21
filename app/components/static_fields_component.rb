# frozen_string_literal: true

# Show a set of metadata fields in a description list element
class StaticFieldsComponent < ViewComponent::Base
  renders_many :fields, 'StaticFieldComponent'

  def render?
    fields.any?
  end

  def call
    content_tag :dl, class: 'row' do
      safe_join(fields)
    end
  end

  # Represent a single set of dt and dd(s) elements that displays a field and it's values
  class StaticFieldComponent < ViewComponent::Base
    # @param [String] label
    # @param [Array] values
    # @param [Array] classes
    def initialize(label:, values: [], classes: [])
      @label = label
      @values = Array.wrap(values)
      @classes = Array.wrap(classes)
    end

    # Properly offset <dd> elements when rendering multiple <dd> values for a field
    # @param [String] value
    # @param [Integer] index
    def value_element(value:, index:)
      classes = index.zero? ? ['col-sm-9'] : %w[offset-sm-3 col-sm-9]
      content_tag :dd, value, class: classes
    end
  end
end
