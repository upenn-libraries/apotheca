# frozen_string_literal: true

module Form
  module Field
    module Switch
      # Component for switch input to be used for boolean fields. Switches are rendered differently
      # than the rest of the fields. They label is rendered to the right of the input
      class Component < ViewComponent::Base
        def initialize(field:, value:, label:, label_col:, input_col:, **options)
          @field = field
          @value = value
          @label = label
          @label_col = label_col
          @input_col = input_col

          # Options for input
          @options = options
          @options[:class] = Array.wrap(@options[:class]).append('form-check-input')
        end

        def call
          render(RowComponent.new(:div, class: 'mb-3')) do
            render(ColumnComponent.new(:div, col: @input_col, offset: @label_col)) do
              render(BaseComponent.new(:div, class: 'form-check form-switch')) do
                safe_join([input, label])
              end
            end
          end
        end

        def label
          render(ColumnComponent.new(:div, col: @label_col, class: 'form-check-label', for: @options[:id])) { @label }
        end

        def input
          hidden_field_tag(@field, 0) + check_box_tag(@field, 1, @value, role: 'switch', **@options)
        end
      end
    end
  end
end
