# frozen_string_literal: true

module SummaryInfo
  # Show a set of metadata fields in a description list element
  class Component < ViewComponent::Base
    renders_many :fields, Field::Component

    # @param [Hash] options
    # @option options [Integer] :cols (3) Number of columns to divide fields into
    # @option options [String] :id (nil) ID for CSS
    # @option options [Array<String>] :classes CSS classes to apply to dl
    # @option options [Array<String>] :col_classes CSS classes to apply to each column div
    def initialize(**options)
      @options = options
      @columns = @options[:cols] || 3
      @id = @options[:id]

      add_classes
    end

    # Add CSS classes to control description list display on small vs large screens
    def add_classes
      # Display columns stacked on small screens and side-by-sie on larger screens
      list_classes = %w[d-flex flex-column mt-4 mb-5]
      list_classes_lg = %w[flex-lg-row justify-content-lg-between gap-lg-4]
      @list_classes = Array.wrap(@options[:classes]).push(list_classes, list_classes_lg)

      # Display each column as specified
      @col_classes = Array.wrap(@options[:col_classes])
    end

    # Divide fields into the specified number of columns (default: 3)
    def columns
      fields.in_groups(@columns).map do |field_group|
        content_tag(:div, class: @col_classes) do
          safe_join(field_group)
        end
      end
    end

    # Render the description list containing columns of label/value pairs
    def call
      render(BaseComponent.new(:dl, class: @list_classes, id: @id)) do
        safe_join(columns)
      end
    end
  end
end
