# frozen_string_literal: true

class ItemResource < Valkyrie::Resource
  include ModificationDetails

  class DescriptiveMetadata < Valkyrie::Resource
    # All descriptive metadata fields
    FIELDS = %i[
      title abstract description call_number collection contributor personal_name corporate_name
      coverage creator date format geographic_subject subject identifier includes item_type
      language notes provenance publisher relation rights source bibnumber
    ].freeze

    FIELDS.each do |field|
      attribute field, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    end

    def to_export
      attributes.slice(*FIELDS)
    end
  end

  class StructuralMetadata < Valkyrie::Resource
    attribute :viewing_direction, Valkyrie::Types::String
    attribute :viewing_hint, Valkyrie::Types::String

    # List assets in the order that they should be displayed. May not include all assets.
    attribute :arranged_asset_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
  end

  attribute :unique_identifier, Valkyrie::Types::String
  attribute :human_readable_name, Valkyrie::Types::String
  attribute :thumbnail_asset_id, Valkyrie::Types::ID # ID of asset that should be thumbnail
  attribute :internal_notes, Valkyrie::Types::Array.of(Valkyrie::Types::String)
  attribute :descriptive_metadata, DescriptiveMetadata
  attribute :structural_metadata, StructuralMetadata

  attribute :published, Valkyrie::Types::Bool
  attribute :first_published_at, Valkyrie::Types::DateTime
  attribute :last_published_at, Valkyrie::Types::DateTime

  # Asset IDs
  attribute :asset_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).optional

  # @return [Integer]
  def asset_count
    Array.wrap(asset_ids).length
  end

  # @return [Array<Valkyrie::ID>]
  def unarranged_asset_ids
    Array.wrap(asset_ids) - structural_metadata.arranged_asset_ids
  end

  # Is a given Asset ID the designated Asset ID for this Item's thumbnail?
  # @param [Valkyrie::ID] asset_id
  def thumbnail?(asset_id)
    thumbnail_asset_id == asset_id
  end

  # @param [Boolean] include_assets
  def to_export(include_assets: false)
    bulk_export_hash = {
      unique_identifier: unique_identifier,
      human_readable_name: human_readable_name,
      metadata: descriptive_metadata.to_export,
      created_at: created_at&.to_fs(:display),
      created_by: created_by,
      updated_at: updated_at&.to_fs(:display),
      updated_by: updated_by,
      internal_notes: internal_notes,
      published: published,
      first_published_at: first_published_at&.to_fs(:display),
      last_published_at: last_published_at&.to_fs(:display),
      structural: {
        viewing_direction: structural_metadata.viewing_direction,
        viewing_hint: structural_metadata.viewing_hint
      }
    }

    if include_assets
      bulk_export_hash[:assets] = {
        ordered: assets_export(structural_metadata.arranged_asset_ids),
        unordered: assets_export(unarranged_asset_ids)
      }
    end

    bulk_export_hash
  end

  # @param [Array<Valkyrie::ID>] asset_ids
  def assets_export(asset_ids)
    query_service = Valkyrie::MetadataAdapter.find(:postgres).query_service
    asset_resources = query_service.find_many_by_ids(ids: asset_ids)

    asset_ids.map do |asset_id|
      asset = asset_resources.find { |r| r.id == asset_id }
      { filename: asset.original_filename, label: asset.label, annotations: asset.annotations.map(&:text) }
    end
  end
end
