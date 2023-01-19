# frozen_string_literal: true

module Form
  module Field
    # Component that provides a single interface to create form fields with a label and input.
    class Component < ViewComponent::Base

      # Creates a form field consisting of a label and an input. The field is a bootstrap row
      # structured based on the lobel_col and input_col values. Additional options provided are
      # passed to the input.
      #
      # @param [Array<String|Symbol>] field_path to value in model
      # @param [Hash] label_col bootstrap columns to use for label
      # @param [Hash] input_col bootstrap columns to use for input
      # @param [Hash] options for field
      # @option options [String] label text
      # @option options [String|Symbol] size of input and label
      # @option options [Valkyrie::ChangeSet] model for field
      def initialize(*field_path, label_col:, input_col:, **options)
        @field_path = field_path
        @label_col = label_col
        @input_col = input_col
        @options = options

        @model = @options.delete(:model)
        @size = @options.delete(:size)
        @label_text = @options.delete(:label)
        @name = @options.delete(:field) || generate_name
        @value = @options.key?(:value) ? @options.delete(:value) : extract_value # Accounting for value to be nil
        @id = generate_id(@name)
      end

      def generate_id(name)
        name.gsub(/(\[|\]|_)+/, '-').chomp('-')
      end

      def extract_value
        @field_path.reduce(@model) { |value, field| value.send(field) }
      end

      # Recursively generates field name.
      def generate_name
        formatted_field_name(model_name, @field_path.dup, @model)
      end

      def formatted_field_name(field_name, field_path, object)
        return field_name if field_path.empty?

        field = field_path.shift
        new_object = object.send(field)
        field_name << "[#{field}]"

        if object.respond_to?(:multiple?) ? object.multiple?(field) : object.is_a?(Array)
          field_name << '[]'
          formatted_field_name(field_name, field_path, new_object.first)
        else
          formatted_field_name(field_name, field_path, new_object)
        end
      end

      def label_text
        @label_text || @field_path.last.to_s.titlecase
      end

      def model_name
        case @model
        when Valkyrie::ChangeSet
          @model.class.to_s.underscore.delete_suffix('_change_set')
        when Valkyrie::Resource
          @model.class.to_s.underscore.delete_suffix('_resource')
        else
          @model.class.to_s.underscore.downcase
        end
      end
    end
  end
end