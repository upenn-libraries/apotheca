# frozen_string_literal: true

module Form
  module Field
    module Input
      # Component that provides a single interface to create form inputs.
      class Component < ViewComponent::Base
        VALID_TYPES = [:text, :select, :hidden, :textarea, :file, :readonly].freeze

        attr_reader :type, :field

        # @param type [Symbol] type of input
        # @param value [String|Array] values to be displayed inputs
        # @param field [String] field name that should be used when submitting the form
        # @param choices [Array<String>] options for select
        # @param options [Hash] arguments to be passed to the *_tag generator
        def initialize(type:, field:, value: nil, choices: nil, **options)
          @type = type.to_sym
          @value = value
          @field = field
          @choices = choices
          @options = options

          # Validations
          raise ArgumentError, "type must be one of #{VALID_TYPES.join(' ')}" unless VALID_TYPES.include?(@type)
          raise ArgumentError, 'value cannot be array when type is a select' if @type == :select && @value.is_a?(Array)
        end

        def call
          render(ColumnComponent.new(:div, col: { sm: 10 })) { input }
        end

        def input
          case @type
          when :text
            if @value.is_a? Array
              render Multivalued::Component.new(value: @value, field: @field, **@options)
            else
              text_field_tag @field, @value, class: 'form-control form-control-sm', **@options
            end
          when :textarea
            text_area_tag @field, @value, class: 'form-control form-control-sm', **@options
          when :select
            render Select::Component.new(value: @value, field: @field, choices: @choices, **@options)
          when :hidden
            hidden_field_tag @field, @value, **@options
          when :file
            file_field_tag @field, class: 'form-control form-control-sm', **@options
          when :readonly
            content_tag :input, nil, type: :text, class: 'form-control-sm form-control-plaintext', value: @value, **@options
          end
        end
      end
    end
  end
end
