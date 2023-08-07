# frozen_string_literal: true

module ItemDescriptiveMetadata
  class Component < ViewComponent::Base
    ILS = 'ils'
    RESOURCE = 'resource'

    def initialize(descriptive_metadata:)
      @descriptive_metadata = descriptive_metadata
    end

    # Helper method to generate a list of items
    #
    # @param [Array] items
    # @param [TrueClass, FalseClass] add_top_padding
    # @return [String] html unordered list
    def list_of_values(items, add_top_padding: false)
      list_class = add_top_padding ? 'pt-2' : ''
      tag.ul(class: 'list-unstyled mb-0') do
        items&.each_with_index do |item, index|
          concat tag.li(class: index.zero? ? '' : list_class) { field_display(item) }
        end
      end
    end

    # Get field values as unstyled list
    #
    # @param [String] source (ILS vs resource value)
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [String (frozen)]
    def field_values(source, field)
      values = @descriptive_metadata.send("#{source}_metadata")[field]

      tag.td(class: field_class(source, field)) do
        list_of_values(values, add_top_padding: true)
      end
    end

    # Display field values with secondary URI formatting. Recursively display subfield values.
    # For example, this is what the value hash looks like:
    #   {value: 'John Smith', uri: 'john.com', role:[{value: 'Author', uri: 'john.com/author'}]}
    #
    # @param [Hash] value
    # @return [Array] value string and URI html
    def field_display(value)
      subfields = [value[:value]]
      subfields << tag.span(value[:uri], class: 'px-1 small text-secondary') if value[:uri]

      value.except(:value, :uri).each do |k, v|
        subfields << tag.table(class: %w[table table-borderless mb-0]) do
          tag.tbody do
            tag.tr do
              tag.th(k.to_s.titleize, scope: :row) + tag.td do
                list_of_values(v)
              end
            end
          end
        end
      end

      safe_join(subfields)
    end

    # Add bootstrap classes to identify whether field's ILS value will be used or overridden by resource value
    # (ILS value only used if field has no resource value)
    #
    # @param [String] source
    # @param [String] field
    # @return [String] class for field
    # @return [nil] if field does not have an ILS value (no highlight necessary)
    def field_class(source, field)
      return unless @descriptive_metadata.ils_metadata

      values = @descriptive_metadata.send("#{source}_metadata")[field]

      if source == ILS && @descriptive_metadata.object[field].present?
        'opacity-75 text-decoration-line-through'
      elsif values.present?
        'bg-success bg-opacity-10'
      end
    end

    # Check if field has either ILS or resource value (otherwise won't be displayed)
    #
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [TrueClass, FalseClass]
    def field_data_present?(field)
      @descriptive_metadata.ils_metadata&.dig(field).present? || @descriptive_metadata.object[field].present?
    end
  end
end

