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

  # Best title to use when trying to represent an item.
  #
  # @return [String]
  def display_title
    human_readable_name
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

  # Return true if any of the assets have preservation files for download.
  def preservation_bulk_download?
    object.assets.any?(&:preservation_file_id)
  end

  # Return true if any of the assets have access or iiif_image files for download.
  def access_bulk_download?
    object.assets.any? { |a| a.access || a.iiif_image }
  end

  # @return [ItemResourcePresenter::DescriptiveMetadataPresenter]
  def descriptive_metadata
    @descriptive_metadata ||= DescriptiveMetadataPresenter.new(
      object: object.descriptive_metadata,
      ils_metadata: @ils_metadata
    )
  end

  # @return [Array<AssetResource]
  def unarranged_assets
    @unarranged_assets ||= assets.reject { |a| structural_metadata.arranged_asset_ids.include?(a.id) }
  end

  # @return [Array<AssetResource>]
  def arranged_assets
    @arranged_assets ||= assets.select { |a| structural_metadata.arranged_asset_ids.include?(a.id) }
                               .sort_by { |a| structural_metadata.arranged_asset_ids.index(a.id) }
  end

  # @return [Array<AssetResource>]
  def assets
    return [] if asset_ids.blank?

    @assets ||= Query.postgres.find_many_by_ids(ids: asset_ids.dup)
  end

  # Returns thumbnail asset.
  #
  # @return [AssetResource]
  def thumbnail
    return unless thumbnail_asset_id

    @thumbnail ||= Query.postgres.find_by(id: thumbnail_asset_id)
  end

  # Returns true if thumbnail asset has a thumbnail image.
  def thumbnail_image?
    return false unless thumbnail_asset_id

    thumbnail&.thumbnail.present?
  end

  # Returns true if all assets have been backed up to preservation-copy. If no assets are present, returns true.
  def all_assets_backed_up?
    return true if asset_ids.nil?

    Query.postgres.custom_queries.number_with_preservation_backup(asset_ids) == asset_count
  end


  private

  def pg_query_service
    @pg_query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
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
