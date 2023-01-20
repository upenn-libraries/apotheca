# frozen_string_literal: true

module Form
  module Field
    module FormControl
      # Component that provides a single interface to create Bootstrap form control
      # fields (which includes text and file fields).
      class Component < ViewComponent::Base
        def initialize(type:, field:, label_col:, input_col:, value: nil, label: nil, size: nil, **options)
          @type = type
          @field = field
          @value = value
          @size = size
          @label_col = label_col
          @input_col = input_col
          @label = label

          # Options for input
          @options = options
          add_class('form-control')
          add_class("form-control-#{@size}") if @size
          add_class('form-control-plaintext') if @type == :readonly
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
          i = case @type
              when :text
                if @value.is_a? Array
                  render Input::Multivalued::Component.new(value: @value, field: @field, **@options)
                else
                  text_field_tag @field, @value, **@options
                end
              when :textarea
                text_area_tag @field, @value, **@options
              when :file
                file_field_tag @field, **@options
              when :readonly
                content_tag :input, nil, type: :text, value: @value, **@options
              when :email
                email_field_tag @field, @value, **@options
              end
          render(ColumnComponent.new(:div, col: @input_col)) { i }
        end

        def add_class(*classes)
          @options[:class] = Array.wrap(@options[:class]).append(*classes)
        end
      end
    end
  end
end
