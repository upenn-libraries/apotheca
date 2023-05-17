# frozen_string_literal: true

# ChangeSet for Items
class ItemChangeSet < Valkyrie::ChangeSet
  include ModificationDetailsChangeSet
  include LockableChangeSet

  # ChangeSet for Descriptive Metadata
  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    ItemResource::DescriptiveMetadata::FIELDS.each do |field|
      property field, multiple: true

      # Remove blank values from array.
      define_method "#{field}=" do |values|
        super(values&.compact_blank)
      end
    end

    validates :title, presence: true, if: ->(metadata) { metadata.bibnumber.blank? }
  end

  # ChangeSet for Structural Metadata
  class StructuralMetadataChangeSet < Valkyrie::ChangeSet
    VIEWING_DIRECTIONS = %w[right-to-left left-to-right top-to-bottom bottom-to-top].freeze
    VIEWING_HINTS = %w[individual paged].freeze

    property :viewing_direction, multiple: false, required: false
    property :viewing_hint, multiple: false, required: false
    property :arranged_asset_ids, multiple: true, required: true

    validates :viewing_direction, inclusion: VIEWING_DIRECTIONS, allow_nil: true
    validates :viewing_hint, inclusion: VIEWING_HINTS, allow_nil: true

    # Allow emptying of asset arrangement by submitting a blank array
    def arranged_asset_ids=(values)
      super(values.compact_blank)
    end
  end

  # Defining Fields
  property :unique_identifier, multiple: false, required: false
  property :human_readable_name, multiple: false, required: true
  property :thumbnail_asset_id, multiple: false, required: true
  property :internal_notes, multiple: true, required: false # TODO: do we need to remove empty values like we do for DescriptiveMetadata fields?
  property :descriptive_metadata, multiple: false, required: true, form: DescriptiveMetadataChangeSet
  property :structural_metadata, multiple: false, required: true, form: StructuralMetadataChangeSet

  property :published, multiple: false, required: false, default: false
  property :first_published_at, multiple: false, required: false
  property :last_published_at, multiple: false, required: false

  property :asset_ids, multiple: true, required: false

  # Validations
  validates :human_readable_name, presence: true
  validates :published, inclusion: [true, false]
  validates :thumbnail_asset_id, presence: true, included_in: :asset_ids, unless: ->(item) { item.asset_ids.blank? }
  validates :unique_identifier, presence: true, format: { with: %r{\Aark:/}, message: 'must be an ARK' }
  validate :ensure_arranged_asset_ids_are_valid

  # Ensuring arranged_asset_ids are also present in asset_ids.
  def ensure_arranged_asset_ids_are_valid
    return if structural_metadata.arranged_asset_ids.blank?
    return if structural_metadata.arranged_asset_ids.all? { |a| asset_ids&.include?(a) }

    errors.add(:'structural_metadata.arranged_asset_ids', 'are not all included in asset_ids')
  end
end
