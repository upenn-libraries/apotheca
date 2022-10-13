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
  def is_thumbnail?(asset_id)
    thumbnail_asset_id == asset_id
  end
end
