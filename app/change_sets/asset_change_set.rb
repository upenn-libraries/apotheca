# frozen_string_literal: true

class AssetChangeSet < Valkyrie::ChangeSet
  include ModificationDetailsChangeSet

  class AnnotationChangeSet < Valkyrie::ChangeSet
    property :text, multiple: false

    validates :text, presence: true
  end

  class TechnicalMetadataChangeSet < Valkyrie::ChangeSet
    property :raw, multiple: false
    property :mime_type, multiple: false
    property :size, multiple: false
    property :duration, multiple: false
    property :md5, multiple: false
    property :sha256, multiple: false
  end

  class TranscriptionChangeSet < Valkyrie::ChangeSet
    property :mime_type, multiple: false, required: true
    property :contents, multiple: false, required: true

    validates :contents, presence: true
    validates :mime_type, presence: true, inclusion: ['text/plain'] # For now only accepting plain text transcriptions
  end

  class AssetDerivativeChangeSet < DerivativeChangeSet
    TYPES = %w[thumbnail access].freeze

    validates :type, inclusion: TYPES
  end

  # Defining Fields
  property :alternate_ids, multiple: true, required: false
  property :original_filename, multiple: false, required: true
  property :preservation_file_id, multiple: false, required: false
  property :preservation_copies_ids, multiple: true, required: false
  property :technical_metadata, multiple: false, form: TechnicalMetadataChangeSet
  property :label, multiple: false

  collection :derivatives, multiple: true, form: AssetDerivativeChangeSet, populate_if_empty: DerivativeResource

  collection :transcriptions, multiple: true, form: TranscriptionChangeSet, populate_if_empty: AssetResource::Transcription

  collection :annotations, multiple: true, form: AnnotationChangeSet, populate_if_empty: AssetResource::Annotation

  # Validations
  validates :original_filename, presence: true
end
