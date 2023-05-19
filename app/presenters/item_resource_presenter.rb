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
    attr_accessor :ils_metadata

    # define accessors for descriptive metadata fields that first look in ILS metadata, if present
    # This sort-of duplicates the logic in DescriptiveMetadataIndexer#merged_metadata_sources
    ItemResource::DescriptiveMetadata::FIELDS.each do |field|
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
    end

    # Get field values as unstyled list
    #
    # @param [String] source (ILS vs resource value)
    # @param [String] field from ItemResource::DescriptiveMetadata::FIELDS
    # @return [String (frozen)]
    def field_values(source, field)
      field_values = source == 'resource' ? object[field] : ils_metadata[field]

      tag.ul(class: 'list-unstyled mb-0') do
        field_values&.each_with_index do |value, i|
          concat tag.li(value, class: i.zero? ? '' : 'pt-2')
        end
      end
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
