# frozen_string_literal: true

# Presentation logic for an ItemResource
class ItemResourcePresenter < BasePresenter
  # @param [Hash|nil] ils_metadata
  # @param [ItemResource] object
  def initialize(object:, ils_metadata: nil)
    super object: object
    @ils_metadata = ils_metadata
  end

  # @return [ItemResourcePresenter::DescriptiveMetadataPresenter]
  def descriptive_metadata
    @descriptive_metadata ||= DescriptiveMetadataPresenter.new(
      object: object.descriptive_metadata,
      ils_metadata: @ils_metadata
    )
  end

  # presenter for descriptive metadata
  class DescriptiveMetadataPresenter < BasePresenter
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Context
    attr_accessor :ils_metadata, :resource_json_metadata

    # define accessors for descriptive metadata fields that first look in ILS metadata, if present
    # This sort-of duplicates the logic in DescriptiveMetadataIndexer#merged_metadata_sources
    ItemResource::DescriptiveMetadata::Fields.all.each do |field|
      define_method field do
        return ils_metadata[field] if ils_metadata.present? && ils_metadata[field].present?

        object.public_send field
      end
    end

    # @param [ItemResource::DescriptiveMetadata] object
    # @param [Hash, NilClass] ils_metadata
    def initialize(object:, ils_metadata: nil)
      super object: object
      @ils_metadata = ils_metadata&.with_indifferent_access
      @resource_json_metadata = object.to_json_export.with_indifferent_access
    end

    # Get field values as unstyled list
    #
    # @param [String] source (ILS vs resource value)
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [String (frozen)]
    def field_values(source, field)
      field_values = source == 'resource' ? resource_json_metadata[field] : ils_metadata[field]

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
      ils_metadata && object[field].empty? ? 'bg-success bg-opacity-10' : 'opacity-75 text-decoration-line-through'
    end

    # Add bootstrap classes to identify that field's resource value is given precedence over ILS value
    #
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [nil] if field does not have an ILS value (no highlight necessary)
    # @return [String (frozen)] if field has an ILS value
    def field_resource_class(field)
      return unless ils_metadata

      'bg-success bg-opacity-10' if object[field].present?
    end

    # Check if field has either ILS or resource value (otherwise won't be displayed)
    #
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [TrueClass, FalseClass]
    def field_row_data?(field)
      ils_metadata&.dig(field).present? || object[field].present?
    end
  end
end
