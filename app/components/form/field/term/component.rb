# frozen_string_literal: true

module Form
  module Field
    module Term
      # Input for controlled term fields. Supports multivalued fields.
      class Component < ViewComponent::Base
        def initialize(field:, **options)
          @field     = field
          @value     = options.delete(:value)
          @size      = options.delete(:size)
          @label     = options.delete(:label)

          @label_col = options.delete(:label_col)
          @input_col = options.delete(:input_col)

          # Options for input
          @options = options
          @options[:class] = Array.wrap(@options[:class]).append('form-control')
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

                multivalued.with_template { input_element({ label: nil, uri: nil }) }
              end
            else
              input_element(@value)
            end
          end
        end

        def input_element(v)
          render(ColumnComponent.new(:div, class: input_group_classes)) do
            tag.span('Label', class: 'input-group-text') +
              text_field_tag("#{@field}[label]", v[:label], **@options) +
                tag.span('URI', class: 'input-group-text') +
                  text_field_tag("#{@field}[uri]", v[:uri], **@options)
          end
        end

        def input_group_classes
          classes = ['input-group']
          classes << "input-group-#{@size}" if @size
          classes
        end
      end
    end
  end
end
