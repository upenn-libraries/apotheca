class ItemResource < Valkyrie::Resource
  class DescriptiveMetadata < Valkyrie::Resource
    # All descriptive metadata fields
    FIELDS = [
      :title, :abstract, :description,  :call_number, :collection, :contributor, :personal_name, :corporate_name,
      :coverage, :creator, :date,  :format, :geographic_subject, :subject, :identifier, :includes, :item_type,
      :language, :notes,  :provenance, :publisher, :relation, :rights, :source, :bibnumber
    ]

    FIELDS.each do |field|
      attribute field, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    end
  end

  class StructuralMetadata < Valkyrie::Resource
    attribute :viewing_direction, Valkyrie::Types::String
    attribute :viewing_hint, Valkyrie::Types::String

    # List assets in the order that they should be displayed. May not include all assets.
    # File Structure, { type: 'ordered', ids: [] }, { type: 'additional material', ids: [] }
    attribute :arranged_asset_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
  end

  attribute :alternate_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID) # Ark should be stored here?
  attribute :human_readable_name, Valkyrie::Types::String
  attribute :thumbnail_id, Valkyrie::Types::ID # ID of asset that should be thumbnail
  attribute :descriptive_metadata, DescriptiveMetadata
  attribute :structural_metadata, StructuralMetadata

  # published?, first_published_at, last_published_at
  # created_by, updated_by should be a User object

  # Asset IDs
  attribute :asset_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).optional
end
