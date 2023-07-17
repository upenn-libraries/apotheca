# frozen_string_literal: true

module Form
  module Field
    module FormControl
      # Component that provides a single interface to create Bootstrap form control
      # fields (which includes text and file fields). Supports multivalued fields.
      class Component < ViewComponent::Base
        def initialize(type:, field:, **options)
          @type = type
          @field = field

          @label_col = options.delete(:label_col)
          @input_col = options.delete(:input_col)
          @value     = options.delete(:value)
          @size      = options.delete(:size)
          @label     = options.delete(:label)

          # Options for input
          @options = options
          @options[:class] = Array.wrap(@options[:class]).append(*input_classes)
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
            if @value.is_a? Array
              render(Multivalued::Component.new) do |multivalued|
                @value.each do |v|
                  multivalued.with_input { input_element(v) }
                end

                multivalued.with_template { input_element(nil) }
              end
            else
              input_element(@value)
            end
          end
        end

        def input_element(val)
          case @type
          when :text
            text_field_tag @field, val, **@options
          when :textarea
            text_area_tag @field, val, **@options
          when :file
            file_field_tag @field, **@options
          when :readonly
            tag.input(type: :text, value: val, **@options)
          when :email
            email_field_tag @field, val, **@options
          end
        end

        def input_classes
          classes = ['form-control']
          classes << "form-control-#{@size}"  if @size
          classes << 'form-control-plaintext' if @type == :readonly
          classes
        end
      end
    end
  end
end
