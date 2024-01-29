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
    attr_accessor :ils_metadata, :resource_metadata

    # define accessors for descriptive metadata fields that first look in ILS metadata, if present
    # This sort-of duplicates the logic in DescriptiveMetadataIndexer#merged_metadata_sources
    ItemResource::DescriptiveMetadata::Fields.all.each do |field|
      define_method field do
        return ils_metadata.fetch(field, []) if ils_metadata.present? && resource_metadata[field].blank?

        object.public_send field
      end
    end

    # @param [ItemResource::DescriptiveMetadata] object
    # @param [Hash, NilClass] ils_metadata
    def initialize(object:, ils_metadata: nil)
      super object: object
      @ils_metadata = ils_metadata&.with_indifferent_access
      @resource_metadata = object.to_json_export.with_indifferent_access
    end

    def to_h
      ItemResource::DescriptiveMetadata::Fields.all.index_with { |f| send(f) }
    end
  end
end
