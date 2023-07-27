# frozen_string_literal: true

module ItemDescriptiveMetadata
  class Component < ViewComponent::Base
    def initialize(descriptive_metadata_presenter:)
      @descriptive_metadata_presenter = descriptive_metadata_presenter
    end

    # Get field values as unstyled list
    #
    # @param [String] source (ILS vs resource value)
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [String (frozen)]
    def field_values(source, field)
      field_values = source == 'resource' ? @descriptive_metadata_presenter.resource_json_metadata[field] : @descriptive_metadata_presenter.ils_metadata[field]

      tag.ul(class: 'list-unstyled mb-0') do
        field_values&.each_with_index do |value, i|
          concat tag.li(class: i.zero? ? '' : 'pt-2') { field_display(value) }
        end
      end
    end


    def field_display(value)
      subfields = [value[:value]]
      subfields << tag.span(value[:uri], class: 'px-1 small text-secondary') if value[:uri]

      # TODO: This needs a refactor
      value.except(:value, :uri).each do |k, v|
        subfields << tag.table(class: ['table', 'table-borderless', 'mb-0']) do
          tag.tbody do
            tag.tr do
              tag.th(k.to_s.titleize, scope: :row) + tag.td do
                tag.ul(class: 'list-unstyled mb-0') do
                  safe_join(v.map { |t| tag.li(field_display(t)) })
                end
              end
            end
          end
        end
      end

      safe_join(subfields)
    end

    # Add bootstrap classes to identify whether field's ILS value will be used or overridden
    # (ILS value only used if field has no resource value)
    #
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [String (frozen)]
    def field_ils_class(field)
      @descriptive_metadata_presenter.ils_metadata && @descriptive_metadata_presenter.object[field].empty? ? 'bg-success bg-opacity-10' : 'opacity-75 text-decoration-line-through'
    end

    # Add bootstrap classes to identify that field's resource value is given precedence over ILS value
    #
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [nil] if field does not have an ILS value (no highlight necessary)
    # @return [String (frozen)] if field has an ILS value
    def field_resource_class(field)
      return unless @descriptive_metadata_presenter.ils_metadata

      'bg-success bg-opacity-10' if object[field].present?
    end

    # Check if field has either ILS or resource value (otherwise won't be displayed)
    #
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [TrueClass, FalseClass]
    def field_row_data?(field)
      @descriptive_metadata_presenter.ils_metadata&.dig(field).present? || @descriptive_metadata_presenter.object[field].present?
    end
  end
end

