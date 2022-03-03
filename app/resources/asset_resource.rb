class AssetResource < Valkyrie::Resource
  # class Annotation < Valkyrie::Resource
  #   attribute :text
  #   attribute :type # 'table_of_contents'
  #   attribute :location #x,y,w,h # optional
  # end
  #
  class DescriptiveMetadata < Valkyrie::Resource
    attribute :label, Valkyrie::Types::String
    attribute :table_of_contents, Valkyrie::Types::String
  end

  class TechnicalMetadata < Valkyrie::Resource
    attribute :raw, Valkyrie::Types::String
    attribute :mime_type, Valkyrie::Types::String
    attribute :size, Valkyrie::Types::Integer # Size in Bytes
    attribute :duration, Valkyrie::Types::String
    attribute :md5, Valkyrie::Types::String
    attribute :sha256, Valkyrie::Types::String
  end

  attribute :alternate_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID)
  attribute :original_filename, Valkyrie::Types::String
  attribute :file_ids, Valkyrie::Types::Set # Link to where its stored in storage
  attribute :descriptive_metadata, DescriptiveMetadata
  attribute :technical_metadata, TechnicalMetadata

  # attribute :derivatives, DerivativeResource # { type: 'thumbnail', file_id: '', generated_at: '' }

  # attribute :fulltext or :transcription { mime_type: '', contents: '' }
  # attribute :preservation_metadata
  #
  # Potential way to group two preservation copies of file
  # class PreservationFile < Valkyrie::Resource
  #   attribute :preservation_file_id
  #   attribute :deep_preservation_file_id # ID for deep storage copy, duplicate_file_id?, backup_file_id?
  # end
end

