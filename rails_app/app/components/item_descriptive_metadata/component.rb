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
  end
end

