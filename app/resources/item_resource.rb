class ItemResource < Valkyrie::Resource
  class DescriptiveMetadata < Valkyrie::Resource
    # Current Colenda descriptive metadata fields
    attribute :abstract, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :bibnumber, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :call_number, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :collection, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :contributor, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :corporate_name, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :coverage, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :creator, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :date, Valkyrie::Types::Array.of(Valkyrie::Types::String) # Might want to change this to Date
    attribute :description, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :format, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :geographic_subject, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :identifier, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :includes, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :item_type, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :language, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :notes, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :personal_name, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :provenance, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :publisher, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :relation, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :rights, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :source, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :subject, Valkyrie::Types::Array.of(Valkyrie::Types::String)
    attribute :title, Valkyrie::Types::Array.of(Valkyrie::Types::String)
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
  attribute :description, Valkyrie::Types::String # Do we need this?
  attribute :thumbnail_id, Valkyrie::Types::ID # ID of asset that should be thumbnail
  attribute :descriptive_metadata, DescriptiveMetadata
  attribute :structural_metadata, StructuralMetadata

  # published?, first_published_at, last_published_at
  # created_by, updated_by should be a User object

  # Asset IDs
  attribute :asset_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).optional
end