# frozen_string_literal: true

# Presentation logic for an ItemResource
class ItemResourcePresenter
  attr_accessor :resource

  delegate_missing_to :resource

  # TODO: include ILS MD at init? if not here, when?
  def initialize(resource:, ils_metadata: nil)
    @resource = resource
    @ils_metadata = ils_metadata
  end

  # @return [ItemResourcePresenter::DescriptiveMetadataPresenter]
  def descriptive_metadata
    @descriptive_metadata ||= DescriptiveMetadataPresenter.new(
      resource: resource.descriptive_metadata,
      ils_metadata: @ils_metadata
    )
  end

  # presenter for descriptive metadata
  class DescriptiveMetadataPresenter
    attr_accessor :resource, :ils_metadata

    delegate_missing_to :resource

    # define accessors for descriptive metadata fields that first look in ILS metadata, if present
    # This sort-of duplicates the logic in DescriptiveMetadataIndexer#merged_metadata_sources
    ItemResource::DescriptiveMetadata::FIELDS.each do |field|
      define_method field do
        return ils_metadata[field.to_sym] if ils_metadata.present? && ils_metadata[field.to_sym].present?

        resource.public_send field
      end
    end

    # @param [ItemResource::DescriptiveMetadata] resource
    # @param [Hash, NilClass] ils_metadata
    def initialize(resource:, ils_metadata: nil)
      @resource = resource
      @ils_metadata = ils_metadata&.with_indifferent_access
    end
  end
end
