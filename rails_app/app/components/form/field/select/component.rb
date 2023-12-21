# frozen_string_literal: true

module Form
  module Field
    module Select
      # Component for select.
      class Component < ViewComponent::Base
        def initialize(field:, choices:, **options)
          @field = field
          @choices = choices

          @value = options.delete(:value)
          @label_col = options.delete(:label_col)
          @input_col = options.delete(:input_col)
          @label = options.delete(:label)
          @size = options.delete(:size)

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
          render(ColumnComponent.new(:label, col: @label_col, class: classes, for: @options[:id])) { @label }
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
