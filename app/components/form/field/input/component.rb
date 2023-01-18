# frozen_string_literal: true

module Form
  module Field
    module Input
      # Component that provides a single interface to create form inputs.
      class Component < ViewComponent::Base
        VALID_TYPES = [:text, :select, :hidden, :textarea, :file, :readonly, :email, :boolean].freeze

        attr_reader :type, :field

        # @param type [Symbol] type of input
        # @param value [String|Array] values to be displayed inputs
        # @param field [String] field name that should be used when submitting the form
        # @param options [Hash] arguments to be passed to the *_tag generator
        def initialize(type:, field:, value: nil, size: nil, **options)
          @type = type.to_sym
          @value = value
          @field = field
          @size = size
          @options = options

          # Validations
          raise ArgumentError, "type must be one of #{VALID_TYPES.join(' ')}" unless VALID_TYPES.include?(@type)
          raise ArgumentError, 'value cannot be array when type is a select' if @type == :select && @value.is_a?(Array)

          @column_options = @options.delete(:col)

          unless (@type == :select || @type == :hidden || @type == :boolean)
            add_class('form-control')
            add_class("form-control-#{@size}") if @size
          end
        end

        def call
          return input if type == :hidden

          if @column_options
            render(ColumnComponent.new(:div, col: @column_options)) { input }
          else
            input
          end
        end

        def input
          case @type
          when :text
            if @value.is_a? Array
              render Multivalued::Component.new(value: @value, field: @field, **@options)
            else
              text_field_tag @field, @value, **@options
            end
          when :textarea
            text_area_tag @field, @value, **@options
          when :select
            render Select::Component.new(value: @value, field: @field, size: @size, **@options)
          when :hidden
            hidden_field_tag @field, @value, **@options
          when :file
            file_field_tag @field, **@options
          when :readonly
            add_class('form-control-plaintext')
            content_tag :input, nil, type: :text, value: @value, **@options
          when :email
            email_field_tag @field, @value, **@options
          when :boolean
            add_class('form-check-input')
            hidden_field_tag(@field, 0) + check_box_tag(@field, 1, @value, role: 'switch', **@options)
          end
        end

        def add_class(*classes)
          @options[:class] = Array.wrap(@options[:class]).append(*classes)
        end
      end
    end
  end
end
