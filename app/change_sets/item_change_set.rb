# frozen_string_literal: true

class ItemChangeSet < Valkyrie::ChangeSet
  include ModificationDetailsChangeSet

  class DescriptiveMetadataChangeSet < Valkyrie::ChangeSet
    ItemResource::DescriptiveMetadata::FIELDS.each do |field|
      property field, multiple: true

      # Remove blank values from array.
      define_method "#{field}=" do |values|
        super(values&.compact_blank)
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
  end

  # Defining Fields
  property :alternate_ids, multiple: true, required: false
  property :human_readable_name, multiple: false, required: true
  property :thumbnail_asset_id, multiple: false, required: true
  property :descriptive_metadata, multiple: false, required: true, form: DescriptiveMetadataChangeSet
  property :structural_metadata, multiple: false, required: true, form: StructuralMetadataChangeSet

  property :published, multiple: false, required: false, default: false
  property :first_published_at, multiple: false, required: false
  property :last_published_at, multiple: false, required: false

  property :asset_ids, multiple: true, required: false

  # Validations
  # TODO: Validate that ark is present in alternate_ids
  validates :human_readable_name, presence: true
  validates :published, inclusion: [true, false]
  validates :thumbnail_asset_id, presence: true, included_in: :asset_ids, unless: ->(item) { item.asset_ids.blank? }
  validate :ensure_arranged_asset_ids_are_valid
  validate :ark_present

  # Ensuring arranged_asset_ids are also present in asset_ids.
  def ensure_arranged_asset_ids_are_valid
    return if structural_metadata.arranged_asset_ids.blank?
    return if structural_metadata.arranged_asset_ids.all? { |a| asset_ids&.include?(a) }

    errors.add(:'structural_metadata.arranged_asset_ids', 'are not all included in asset_ids')
  end

  # Ensuring that exactly one ark is present in alternate_ids array.
  def ark_present
    arks = alternate_ids.select { |i| i.to_s.starts_with?('ark:/') }

    errors.add(:alternate_ids, 'must include an ARK') if arks.count.zero?
    errors.add(:alternate_ids, 'can only include one ARK') if arks.count > 1
  end
end
