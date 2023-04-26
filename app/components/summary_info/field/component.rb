# frozen_string_literal: true

module SummaryInfo
  module Field
    # Represent a single set of dt and dd(s) elements that displays a field and its value
    class Component < ViewComponent::Base
      # @param [String|NilClass] label for individual field
      # @param [TrueClass, FalseClass] spacer (blank dt and dd) for alignment purposes
      # @param [Hash] options
      # @option options [Array<String>] :field_classes CSS classes to apply to the field's container div
      # @option options [Array<String>] :label_classes CSS classes to apply to the field's label dt
      # @option options [Array<String>] :value_classes CSS classes to apply to the field's value dd
      def initialize(label = nil, spacer: false, **options)
        @label = label
        @spacer = spacer
        @options = options

        add_classes
      end

      # Add CSS classes to control label/value pair display
      def add_classes
        @field_classes = Array.wrap(@options[:classes])
        @label_classes = Array.wrap(@options[:label_classes])
        @value_classes = Array.wrap(@options[:value_classes])

        # Add field/spacer dependent CSS classes
        @spacer ? spacer_classes : field_classes
      end

      def spacer_classes
        # Hide spacer completely when fields are stacked
        # Add 'invisible' when fields are in columns (for accessibility)
        # Add padding to dt and dd to match vertical space used by actual fields
        @field_classes.push(%w[invisible d-none d-lg-flex])
        @label_classes.push('pb-4')
        @value_classes.push('pb-4')
      end

      def field_classes
        # Display label/value side-by-side on small screen (fields in one column)
        # Display stacked on large screen (fields in multiple columns)
        @field_classes.push(%w[d-flex flex-wrap flex-row flex-lg-column flex-fill mb-1 mb-lg-2])
        @label_classes.push(%w[me-2 me-lg-0])
      end

      # Construct label
      def label
        @label &&= "#{@label}:"
        content_tag :dt, @label, class: @label_classes
      end

      # Construct value
      def value
        content_tag :dd, content, class: @value_classes
      end

      # Display label and value inside container div
      def call
        render BaseComponent.new(:div, class: @field_classes) do
          safe_join([label, value])
        end
      end
    end
  end
end
