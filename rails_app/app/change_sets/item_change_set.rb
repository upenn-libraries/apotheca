# frozen_string_literal: true

# ChangeSet for ItemResource
class ItemChangeSet < ChangeSet
  include ModificationDetailsChangeSet
  include LockableChangeSet

  DERIVATIVE_TYPES = %w[iiif_manifest iiif_v3_manifest pdf].freeze
  OCR_STRATEGIES = DerivativeService::Asset::Generator::Image::OCR::ALL_ENGINES.freeze

  # ChangeSet for Structural Metadata
  class StructuralMetadataChangeSet < ChangeSet
    VIEWING_DIRECTIONS = %w[right-to-left left-to-right top-to-bottom bottom-to-top].freeze
    VIEWING_HINTS = %w[individuals paged].freeze

    property :viewing_direction, multiple: false, required: false
    property :viewing_hint, multiple: false, required: false
    property :arranged_asset_ids, multiple: true, required: true

    validates :viewing_direction, inclusion: VIEWING_DIRECTIONS, allow_nil: true
    validates :viewing_hint, inclusion: VIEWING_HINTS, allow_nil: true

    # Allow emptying of asset arrangement by submitting a blank array
    def arranged_asset_ids=(values)
      super(compact_value(values))
    end

    def viewing_direction=(value)
      super(compact_value(value))
    end

    def viewing_hint=(value)
      super(compact_value(value))
    end
  end

  # ChangeSet for Item Derivatives
  class ItemDerivativeChangeSet < DerivativeChangeSet
    validates :type, inclusion: DERIVATIVE_TYPES
  end

  # Defining Fields
  property :unique_identifier, multiple: false, required: false
  property :human_readable_name, multiple: false, required: true
  property :thumbnail_asset_id, multiple: false, required: true
  property :internal_notes, multiple: true, required: false
  property :descriptive_metadata, multiple: false, required: true, form: DescriptiveMetadataChangeSet
  property :structural_metadata, multiple: false, required: true, form: StructuralMetadataChangeSet

  # Letting derivatives be defined as a `collection` because derivatives are always set via the setter and not the
  # `validate` method therefore we don't run into problems when deleting derivatives. More information about this
  # can be found here: https://gitlab.library.upenn.edu/dld/digital-repository/apotheca/-/issues/202
  collection :derivatives, multiple: true, form: ItemDerivativeChangeSet, populate_if_empty: DerivativeResource

  property :published, multiple: false, required: false, default: false
  property :first_published_at, multiple: false, required: false
  property :last_published_at, multiple: false, required: false

  property :asset_ids, multiple: true, required: false

  property :ocr_strategy, multiple: false, required: false

  # Validations
  validates :human_readable_name, presence: true
  validates :published, inclusion: [true, false]
  validates :thumbnail_asset_id, presence: true, included_in: :asset_ids, unless: ->(item) { item.asset_ids.blank? }
  validates :unique_identifier, presence: true, format: { with: %r{\Aark:/}, message: 'must be an ARK' }
  validate :ensure_arranged_asset_ids_are_valid
  validates :ocr_strategy, inclusion: OCR_STRATEGIES, allow_nil: true

  # Ensuring arranged_asset_ids are also present in asset_ids.
  def ensure_arranged_asset_ids_are_valid
    return if structural_metadata.arranged_asset_ids.blank?
    return if structural_metadata.arranged_asset_ids.all? { |a| asset_ids&.include?(a) }

    errors.add(:'structural_metadata.arranged_asset_ids', 'are not all included in asset_ids')
  end

  def internal_notes=(values)
    super(compact_value(values))
  end

  def ocr_strategy=(value)
    super(compact_value(value))
  end
end
