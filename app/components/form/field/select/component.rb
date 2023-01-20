# frozen_string_literal: true

module Form
  module Field
    module Select
      # Component for select.
      class Component < ViewComponent::Base
        def initialize(field:, label:, choices:, size: nil, value: nil, input_col: nil, label_col: nil, **options)
          @value = value
          @field = field
          @label = label
          @size = size
          @label_col = label_col
          @input_col = input_col
          @choices = choices

          # Options for input
          @options = options
          @options[:class] = Array.wrap(@options[:class]).append('form-select')
          @options[:class] = @options[:class].append("form-select-#{@size}") if @size
        end

        def call
          render(RowComponent.new(:div, class: 'mb-3')) do
            safe_join([label, input])
          end
        end

        def label
          classes = ['col-form-label']
          classes << "col-form-label-#{@size}" if @size
          render(ColumnComponent.new(:div, col: @label_col, class: classes, for: @options[:id])) { @label }
        end

        def input
          render(ColumnComponent.new(:div, col: @input_col)) do
            select_tag(@field, options_for_select(@choices, selected: @value), **@options)
          end
        end
      end
    end
  end
end
