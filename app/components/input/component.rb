# frozen_string_literal: true

module Input
  # Component that provides a single interface to create form inputs.
  class Component < ViewComponent::Base
    VALID_TYPES = [:text, :select, :hidden, :textarea, :file, :readonly].freeze

    attr_reader :type

    # @param type [Symbol] type of input
    # @param label [String] label for input
    # @param value [String|Array] values to be displayed inputs
    # @param field [String] field name that should be used when submitting the form
    # @param options [Array<String>] options for select
    # @param args [Hash] arguments to be passed to the *_tag generator
    def initialize(type:, label:, field:, value: nil, options: nil, **args)
      @type = type.to_sym
      @label = label.to_s.titlecase
      @value = value
      @field = field
      @options = options
      @args = args
      @id = label.to_s.downcase.tr(' ', '-')

      # Validations
      raise ArgumentError, "type must be one of #{VALID_TYPES.join(' ')}" unless VALID_TYPES.include?(@type)
      raise ArgumentError, 'value cannot be array when type is a select' if @type == :select && @value.is_a?(Array)
    end

    def input
      case @type
      when :text
        if @value.is_a? Array
          render Multivalued::Component.new(id: @id, value: @value, field: @field)
        else
          text_field_tag @field, @value, class: 'form-control form-control-sm', id: @id
        end
      when :textarea
        text_area_tag @field, @value, class: 'form-control form-control-sm', id: @id, **@args
      when :select
        render Select::Component.new(id: @id, value: @value, field: @field, options: @options, **@args)
      when :hidden
        hidden_field_tag @field, @value, id: @id
      when :file
        file_field_tag @field, class: 'form-control form-control-sm', id: @id
      when :readonly
        content_tag :input, nil, type: :text, class: 'form-control-sm form-control-plaintext', value: @value
      else
        # should never happen due to validation
      end
    end
  end
end
