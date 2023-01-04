# frozen_string_literal: true

module Form
  module Field
    # Component that provides a single interface to create form fields with a label and input.
    class Component < ViewComponent::Base
      renders_one :label, ->(text, **options, &block) do
        Label::Component.new(text, for: @id, size: @size, **options, &block)
      end

      renders_one :input, ->(**options, &block) do
        Input::Component.new(id: @id, size: @size, field: @name, value: @value, **options, &block)
      end

      def initialize(*field_path, model: nil, size: nil, **options)
        @field_path = field_path
        @model = model
        @size = size
        @options = options

        @options[:class] = Array.wrap(@options[:class]).append('mb-3')

        @name = @options.delete(:field) || generate_name
        @value = @options.key?(:value) ? @options.delete(:value) : extract_value # Accounting for value to be nil

        @id = generate_id(@name)
      end

      def generate_id(name)
        name.gsub(/(\[|\]|_)+/, '-').chomp('-')
      end

      def extract_value
        return unless @model.is_a?(Valkyrie::ChangeSet)

        @field_path.reduce(@model) { |value, field| value.send(field) }
      end

      def generate_name
        return unless @model.is_a?(Valkyrie::ChangeSet)

        name = model_name
        formatted_field_name(name, @field_path.dup, @model)
      end

      def formatted_field_name(field_name, field_path, object)
        return field_name if field_path.empty?

        field = field_path.shift
        new_object = object.send(field) # TODO: if this does not succeed throw an error
        field_name << "[#{field}]"
        field_name << "[]" if object.multiple?(field)
        if object.multiple?(field)
          formatted_field_name(field_name, field_path, new_object.first)
        else
          formatted_field_name(field_name, field_path, new_object)
        end
      end

      def model_name
        if @model.is_a? Valkyrie::ChangeSet
          @model.class.to_s.underscore.delete_suffix('_change_set')
        else
          # TODO: if its an active record model do something else?
        end
      end

      def call
        return input if input.type == :hidden

        render(RowComponent.new(:div, **@options)) do
          safe_join([label, input])
        end
      end
    end
  end
end