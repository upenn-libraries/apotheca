# frozen_string_literal: true

# Presentation logic for an ItemResource
class ItemResourcePresenter < BasePresenter
  include Rails.application.routes.url_helpers

  # @param [Hash|nil] ils_metadata
  # @param [ItemResource] object
  def initialize(object:, ils_metadata: nil)
    super object: object
    @ils_metadata = ils_metadata
  end

  # @return [String] The URL for this ItemResource on the Apotheca site.
  def apotheca_url
    url_for(controller: 'items', action: 'show', id: object.id, host: Settings.app_url)
  end

  # Returning string that doesn't have any special characters or spaces that can be
  # used for a filename or url.
  #
  # @return [String]
  def parameterize
    descriptive_metadata.title.first[:value].parameterize
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

    # Return a hash representation of the descriptive metadata. Converts any resource objects to hashes.
    def to_h
      ItemResource::DescriptiveMetadata::Fields.all.index_with do |f|
        send(f).map do |value|
          value.is_a?(Valkyrie::Resource) ? value.to_json_export : value
        end
      end
    end
  end
end
