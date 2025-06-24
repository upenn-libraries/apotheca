# frozen_string_literal: true

# Item model; contains attributes and helper methods
class ItemResource < Valkyrie::Resource
  include ModificationDetails
  include Lockable

  # Data about how a ItemResource's assets are organized
  class StructuralMetadata < Valkyrie::Resource
    attribute :viewing_direction, Valkyrie::Types::Strict::String.optional
    attribute :viewing_hint, Valkyrie::Types::Strict::String.optional

    # List assets in the order that they should be displayed. May not include all assets.
    attribute :arranged_asset_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
  end

  attribute :unique_identifier, Valkyrie::Types::Strict::String
  attribute :human_readable_name, Valkyrie::Types::Strict::String
  attribute :thumbnail_asset_id, Valkyrie::Types::Params::ID # ID of asset that should be thumbnail
  attribute :internal_notes, Valkyrie::Types::Array.of(Valkyrie::Types::Strict::String)
  attribute :descriptive_metadata, DescriptiveMetadata
  attribute :structural_metadata, StructuralMetadata

  attribute :published, Valkyrie::Types::Strict::Bool
  attribute :first_published_at, Valkyrie::Types::Strict::DateTime.optional
  attribute :last_published_at, Valkyrie::Types::Strict::DateTime.optional

  # Asset IDs
  attribute :asset_ids, Valkyrie::Types::Array.of(Valkyrie::Types::Params::ID).optional

  # Item-level derivatives, like IIIF Manifest.
  attribute :derivatives, Valkyrie::Types::Array.of(DerivativeResource)

  attribute :ocr_strategy, Valkyrie::Types::Strict::String.optional

  # @return [Integer]
  def asset_count
    Array.wrap(asset_ids).length
  end

  # @return [Array<Valkyrie::ID>]
  def unarranged_asset_ids
    Array.wrap(asset_ids) - structural_metadata.arranged_asset_ids
  end

  # @return [Array<AssetResource>]
  def arranged_assets
    @arranged_assets ||= pg_query_service.find_many_by_ids(ids: structural_metadata.arranged_asset_ids.dup)
                                         .sort_by { |a| structural_metadata.arranged_asset_ids.index(a.id) }
  end

  # Is a given Asset ID the designated Asset ID for this Item's thumbnail?
  # @param [Valkyrie::ID] asset_id
  def thumbnail?(asset_id)
    thumbnail_asset_id == asset_id
  end

  # @return [TrueClass, FalseClass]
  def bibnumber?
    descriptive_metadata&.bibnumber.try(:any?)
  end

  # @return [DerivativeResource]
  def iiif_manifest
    derivatives.find(&:iiif_manifest?)
  end

  # @return [DerivativeResource]
  def pdf
    derivatives.find(&:pdf?)
  end

  # @param [Boolean] include_assets
  def to_json_export(include_assets: false)
    bulk_export_hash = {
      unique_identifier: unique_identifier,
      uuid: id,
      human_readable_name: human_readable_name,
      apotheca_url: presenter.apotheca_url,
      metadata: descriptive_metadata.to_json_export,
      created_at: date_created&.to_fs(:display),
      created_by: created_by,
      updated_at: date_updated&.to_fs(:display),
      updated_by: updated_by,
      internal_notes: internal_notes,
      published: published,
      asset_count: asset_count,
      ocr_strategy: ocr_strategy,
      first_published_at: first_published_at&.to_fs(:display),
      last_published_at: last_published_at&.to_fs(:display),
      structural: { viewing_direction: structural_metadata.viewing_direction,
                    viewing_hint: structural_metadata.viewing_hint }
    }

    if include_assets
      bulk_export_hash[:assets] = {
        arranged: assets_export(structural_metadata.arranged_asset_ids),
        unarranged: assets_export(unarranged_asset_ids)
      }
    end

    bulk_export_hash
  end

  # @param [Array<Valkyrie::ID>] asset_ids
  def assets_export(asset_ids)
    asset_resources = pg_query_service.find_many_by_ids(ids: asset_ids)

    asset_ids.map do |asset_id|
      asset = asset_resources.find { |r| r.id == asset_id }
      { filename: asset.original_filename, label: asset.label, annotations: asset.annotations.map(&:text) }
    end
  end

  # @return [ItemResourcePresenter]
  def presenter
    @presenter ||= create_presenter
  end

  # Best title to use when trying to represent an item.
  #
  # @return [String]
  def display_title
    human_readable_name
  end

  # Returns thumbnail asset.
  #
  # @return [AssetResource]
  def thumbnail
    return unless thumbnail_asset_id

    @thumbnail ||= pg_query_service.find_by(id: thumbnail_asset_id)
  end

  # Returns true if thumbnail asset has a thumbnail image.
  def thumbnail_image?
    return false unless thumbnail_asset_id

    thumbnail&.thumbnail.present?
  end

  # Returns true if all assets have been backed up to preservation-copy. If no assets are present, returns true.
  def all_assets_backed_up?
    return true if asset_ids.nil?

    pg_query_service.custom_queries.number_with_preservation_backup(asset_ids) == asset_count
  end

  # Converts languages found in metadata to a list of ISO 639-2 language codes. We return both
  # the bibliographic and terminological codes when present. Usually these
  # language codes are used when running OCR on images.
  #
  # @return [Array<String>]
  def language_codes
    languages = Array.wrap(presenter.descriptive_metadata.language)
    languages.pluck(:value).flat_map { |l| ISO_639.find_by_english_name(l)&.first(2) }.compact_blank
  end

  private

  def create_presenter
    ils_metadata = bibnumber? ? solr_query_service.custom_queries.ils_metadata_for(id: id.to_s) : nil
    ItemResourcePresenter.new(object: self, ils_metadata: ils_metadata)
  end

  def solr_query_service
    @solr_query_service ||= Valkyrie::MetadataAdapter.find(:index_solr).query_service
  end

  def pg_query_service
    @pg_query_service ||= Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
