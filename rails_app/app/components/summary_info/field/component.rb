# frozen_string_literal: true

module SummaryInfo
  module Field
    # Represent a single set of dt and dd(s) elements that displays a field and its value
    class Component < ViewComponent::Base
      # @param [String|NilClass] label for individual field
      # @param [TrueClass, FalseClass] spacer (blank dt and dd) for alignment purposes
      # @param [Hash] options
      # @option options [Array<String>] :field_classes (nil) CSS classes to apply to the field's container div
      # @option options [Array<String>] :label_classes (nil) CSS classes to apply to the field's label dt
      # @option options [Array<String>] :value_classes (nil) CSS classes to apply to the field's value dd
      def initialize(label = nil, spacer: false, **options)
        @label = label
        @spacer = spacer
        @options = options

        add_classes
      end

      # Add CSS classes defined at component initialization
      def add_classes
        @field_classes = Array.wrap(@options[:classes])
        @label_classes = Array.wrap(@options[:label_classes])
        @value_classes = Array.wrap(@options[:value_classes])

        # Add additional CSS classes to fields vs spacers
        @spacer ? spacer_classes : field_classes
      end

      # Add CSS classes for the display of a spacer
      #
      # Include 'invisible' for accessibility (visibility: hidden)
      # Hide completely when fields are stacked (display: none)
      # Occupy vertical space when fields are in columns (display: block)
      # Add padding to dt and dd to match vertical space occupied by actual fields
      def spacer_classes
        @field_classes.push(%w[invisible d-none d-lg-flex])
        @label_classes.push('pb-4')
        @value_classes.push('pb-4')
      end

      # Add CSS classes for the display of a field with label/value
      #
      # Display label/value side-by-side on small screens (with all fields in single column)
      # Display label/value stacked on large screens (with fields divided into multiple columns)
      def field_classes
        @field_classes.push(%w[d-flex flex-wrap flex-row flex-lg-column flex-fill mb-1 mb-lg-2])
        @label_classes.push(%w[me-2 me-lg-0])
      end

      # Construct field label
      def label
        label_display = @label ? "#{@label}:" : nil
        tag.dt(label_display, class: @label_classes)
      end

      # Construct field value
      def value
        tag.dd(content, class: @value_classes)
      end

      # Display field label and value inside a container div
      def call
        render BaseComponent.new(:div, class: @field_classes) do
          safe_join([label, value])
        end
      end
    end
  end
end
