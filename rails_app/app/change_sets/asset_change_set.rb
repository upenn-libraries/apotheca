# frozen_string_literal: true

# ChangeSet for AssetResource
class AssetChangeSet < ChangeSet
  include ModificationDetailsChangeSet
  include LockableChangeSet

  TRANSCRIPTION_MIME_TYPES = ['text/plain'].freeze

  # ChangeSet for Technical Metadata
  class TechnicalMetadataChangeSet < ChangeSet
    property :raw, multiple: false
    property :mime_type, multiple: false
    property :size, multiple: false
    property :duration, multiple: false
    property :md5, multiple: false
    property :sha256, multiple: false
  end

  # ChangeSet for Asset Derivatives
  class AssetDerivativeChangeSet < DerivativeChangeSet
    TYPES = %w[thumbnail access].freeze

    validates :type, inclusion: TYPES
  end

  # Defining Fields
  property :original_filename, multiple: false, required: true
  property :preservation_file_id, multiple: false, required: false
  property :preservation_copies_ids, multiple: true, required: false
  property :technical_metadata, multiple: false, form: TechnicalMetadataChangeSet
  property :preservation_events, multiple: true, required: false

  # name of source system for a migration action
  property :migrated_from, multiple: false, virtual: true

  # virtual property to aggregate events before batch adding them to the change set. this ensures we
  # can set events with identical timestamps
  property :temporary_events, multiple: true, virtual: true

  # Virtual property to hold expected_checksum that will be used the validate the checksum after file is ingested. Should
  # only be provided when ingesting a new file.
  property :expected_checksum, multiple: false, virtual: true

  property :label, multiple: false

  # Letting derivatives be defined as a `collection` because derivatives are always set via the setter and not the
  # `validate` method therefore we don't run into problems when deleting derivatives. More information about this
  # can be found here: https://gitlab.library.upenn.edu/dld/digital-repository/apotheca/-/issues/202
  collection :derivatives, multiple: true, form: AssetDerivativeChangeSet, populate_if_empty: DerivativeResource

  property :transcriptions, multiple: true, required: false, default: [],
           type: Valkyrie::Types::Array(AssetResource::Transcription)

  property :annotations, multiple: true, required: false, default: [],
           type: Valkyrie::Types::Array(AssetResource::Annotation)

  # Validations
  validates :original_filename, presence: true, if: ->(asset) { asset.preservation_file_id.present? }
  #   File should be set on update.
  validates :preservation_file_id, presence: true, if: ->(asset) { !asset.resource.new_record }
  validates :annotations, each_object: { text: { required: true } }
  validates :transcriptions, each_object: {
    contents:  { required: true },
    mime_type: { required: true, accepted_values: TRANSCRIPTION_MIME_TYPES }
  }

  def annotations=(values)
    super(compact_value(values))
  end

  def transcriptions=(values)
    super(compact_value(values))
  end

  def label=(value)
    super(compact_value(value))
  end
end
