class ItemChangeSet < Valkyrie::ChangeSet
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    property :abstract
    property :bibnumber
    property :call_number
    property :collection
    property :contributor
    property :corporate_name
    property :coverage
    property :creator
    property :date
    property :description
    property :format
    property :geographic_subject
    property :identifier
    property :includes
    property :item_type
    property :language
    property :notes
    property :personal_name
    property :provenance
    property :publisher
    property :relation
    property :rights
    property :source
    property :subject
    property :title, required: true

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

  # Validations
  # TODO: Validate that ark is present in alternate_ids
  validates :human_readable_name, presence: true
end