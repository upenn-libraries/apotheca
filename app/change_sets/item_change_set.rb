# frozen_string_literal: true

class ItemChangeSet < Valkyrie::ChangeSet
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    ItemResource::DescriptiveMetadata::FIELDS.each do |field|
      property field, multiple: true

      # Remove blank values from array.
      define_method "#{field}=" do |values|
        super(values.compact_blank)
      end
    end

    validates :title, presence: true
  end

  class StructuralMetadataChangeSet < Valkyrie::ChangeSet
    VIEWING_DIRECTIONS = %w[right-to-left left-to-right top-to-bottom bottom-to-top].freeze
    VIEWING_HINTS = %w[individual paged].freeze

    property :viewing_direction, multiple: false, required: false
    property :viewing_hint, multiple: false, required: false
    property :arranged_asset_ids, multiple: true, required: true

    validates :viewing_direction, inclusion: VIEWING_DIRECTIONS, allow_nil: true
    validates :viewing_hint, inclusion: VIEWING_HINTS, allow_nil: true
    # TODO: validate at least one ordered asset id is present
    # TODO: validate that all arranged asset ids are listed as a member id
  end

  # Defining Fields
  property :alternate_ids, multiple: true, required: false
  property :human_readable_name, multiple: false, required: true
  property :thumbnail_id, multiple: false, required: true
  property :descriptive_metadata, multiple: false, required: true, form: DescriptiveMetadataChangeSet
  property :structural_metadata, multiple: false, required: true, form: StructuralMetadataChangeSet

  property :published, multiple: false, required: false, default: false
  property :first_published_at, multiple: false, required: false
  property :last_published_at, multiple: false, required: false

  property :asset_ids, multiple: true, required: false

  # Validations
  # TODO: Validate that ark is present in alternate_ids
  # TODO: Validate thumbnail_id is included in asset_ids
  validates :human_readable_name, presence: true
  validates :published, inclusion: [true, false]
end
