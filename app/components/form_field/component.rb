# frozen_string_literal: true

module FormField
  class Component < ViewComponent::Base
    VALID_TYPES = [:text, :select]

    # @param type [Symbol] type of input
    # @param label [String] label for input
    # @param value [String|Array] values to be displayed inputs
    # @param field [String] field name that should be used when submitting the form
    # @param options [Array<String>] options for select
    def initialize(type:, label:, value:, field:, options: nil)
      @type = type.to_sym
      @label = label.to_s.titlecase
      @value = value
      @field = field
      @options = options
      @id = label.to_s.downcase.tr(' ', '-')

      # Validations
      raise ArgumentError, "type must be one of #{VALID_TYPES.join(' ')}" unless VALID_TYPES.include?(@type)
      raise ArgumentError, "value cannot be array when type is a select" if @type == :select && @value.is_a?(Array)
    end

    def input
      case @type
      when :text
        if @value.is_a? Array
          render MultivaluedInput::Component.new(id: @id, value: @value, field: @field)
        else
          text_field_tag @field, @value, class: 'form-control', id: @id
        end
      when :select
        render SelectInput::Component.new(id: @id, value: @value, field: @field, options: @options)
      else
        # should never happen due to validation
      end
    end
  end
end