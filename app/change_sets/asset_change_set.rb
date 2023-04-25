# frozen_string_literal: true

class AssetChangeSet < Valkyrie::ChangeSet
  include ModificationDetailsChangeSet
  include LockableChangeSet

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
    # For now only accepting plain text transcriptions
    VALID_MIME_TYPES = ['text/plain'].freeze

    property :mime_type, multiple: false, required: true
    property :contents, multiple: false, required: true

    validates :contents, presence: true
    validates :mime_type, presence: true, inclusion: VALID_MIME_TYPES
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
  property :preservation_events, multiple: true, required: false

  # name of source system for a migration action
  property :migrated_from, multiple: false, virtual: true

  # virtual property to aggregate events before batch adding them to the change set. this ensures we
  # can set events with identical timestamps
  property :temporary_events, multiple: true, virtual: true

  property :label, multiple: false

  collection :derivatives, multiple: true, form: AssetDerivativeChangeSet, populate_if_empty: DerivativeResource

  collection :transcriptions, multiple: true, form: TranscriptionChangeSet, populator: :transcriptions!

  collection :annotations, multiple: true, form: AnnotationChangeSet, populator: :annotations!

  # Validations
  validates :original_filename, presence: true, if: ->(asset) { asset.preservation_file_id.present? }
  validates :preservation_file_id, presence: true, if: lambda { |asset|
                                                         !asset.resource.new_record
                                                       } # Preservation file should be set on update.

  def transcriptions!(collection:, index:, fragment:, **)
    if fragment['contents'].blank? && fragment[:contents].blank?
      skip!
    elsif (item = collection[index])
      item
    else
      collection.insert(index, AssetResource::Transcription.new)
    end
  end

  def annotations!(collection:, index:, fragment:, **)
    if fragment['text'].blank? && fragment[:text].blank?
      skip!
    elsif (item = collection[index])
      item
    else
      collection.insert(index, AssetResource::Annotation.new)
    end
  end
end
