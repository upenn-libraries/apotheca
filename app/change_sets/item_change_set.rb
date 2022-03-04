class ItemChangeSet < Valkyrie::ChangeSet
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    ItemResource::DescriptiveMetadata::FIELDS.each do |field|
      property field, multiple: true
    end

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
