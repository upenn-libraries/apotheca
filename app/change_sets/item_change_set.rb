class ItemChangeSet < Valkyrie::ChangeSet
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    property :abstract, multiple: true
    property :bibnumber, multiple: true
    property :call_number, multiple: true
    property :collection, multiple: true
    property :contributor, multiple: true
    property :corporate_name, multiple: true
    property :coverage, multiple: true
    property :creator, multiple: true
    property :date, multiple: true
    property :description, multiple: true
    property :format, multiple: true
    property :geographic_subject, multiple: true
    property :identifier, multiple: true
    property :includes, multiple: true
    property :item_type, multiple: true
    property :language, multiple: true
    property :notes, multiple: true
    property :personal_name, multiple: true
    property :provenance, multiple: true
    property :publisher, multiple: true
    property :relation, multiple: true
    property :rights, multiple: true
    property :source, multiple: true
    property :subject, multiple: true
    property :title, multiple: true,required: true

    validates :title, presence: true
  end

  class StructuralMetadataChangeSet < Valkyrie::ChangeSet
    property :viewing_direction, multiple: false, required: false
    property :viewing_hint, multiple: false, required: false
    property :arranged_asset_ids, multiple: true, required: true

    # TODO: validate at least one ordered asset id is present
    # TODO: validate that all ordered asset ids are listed as a member id
  end

  # Defining Fields
  property :alternate_ids, multiple: true, required: false
  property :human_readable_name, multiple: false, required: true
  property :asset_ids, multiple: true, required: false
  property :descriptive_metadata, multiple: false, required: true, form: DescriptiveMetadataChangeSet
  property :structural_metadata, multiple: false, required: true, form: StructuralMetadataChangeSet
  property :thumbnail_id, multiple: false, required: true

  # Validations
  # TODO: Validate that ark is present in alternate_ids
  validates :human_readable_name, presence: true
end
