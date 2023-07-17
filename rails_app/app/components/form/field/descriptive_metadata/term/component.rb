# frozen_string_literal: true

module Form
  module Field
    module DescriptiveMetadata
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

            @subfields = options.delete(:subfields) || []

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

                  multivalued.with_template { input_element(nil) }
                end
              else
                input_element(@value)
              end
            end
          end

          def input_element(v)
            v = { value: nil, uri: nil } if v.nil?

            render(RowComponent.new(:div, class: @subfields.present? ? 'mb-3' : '')) {
              render(ColumnComponent.new(:div, col: 12, class: input_group_classes)) {
                tag.span('Value', class: 'input-group-text') +
                  text_field_tag("#{@field}[value]", v[:value], **@options) +
                  tag.span('URI', class: 'input-group-text') +
                  text_field_tag("#{@field}[uri]", v[:uri], **@options)
              }
            } + safe_join(subfields(v))
          end

          def subfields(v)
            @subfields.map do |subfield_name, config|
              render(DescriptiveMetadata::Component.new(
                field: "#{@field}[#{subfield_name}][]",
                value: v[subfield_name] || [],
                label: subfield_name.to_s.titleize,
                config: config,
                label_col: @label_col,
                input_col: @input_col,
                size: @size
              # TODO: missing :id,
              ))
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
end
