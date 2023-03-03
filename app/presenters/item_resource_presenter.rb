# frozen_string_literal: true

# Presentation logic for an ItemResource
class ItemResourcePresenter < BasePresenter
  # @param [Hash] ils_metadata
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
    attr_accessor :ils_metadata

    # define accessors for descriptive metadata fields that first look in ILS metadata, if present
    # This sort-of duplicates the logic in DescriptiveMetadataIndexer#merged_metadata_sources
    ItemResource::DescriptiveMetadata::FIELDS.each do |field|
      define_method field do
        return ils_metadata[field.to_sym] if ils_metadata.present? && ils_metadata[field.to_sym].present?

        object.public_send field
      end
    end

    # @param [ItemResource::DescriptiveMetadata] object
    # @param [Hash, NilClass] ils_metadata
    def initialize(object:, ils_metadata: nil)
      super object: object
      @ils_metadata = ils_metadata&.with_indifferent_access
    end
  end
end
