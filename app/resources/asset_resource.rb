# frozen_string_literal: true

class AssetResource < Valkyrie::Resource
  include ModificationDetails

  class Annotation < Valkyrie::Resource
    attribute :text, Valkyrie::Types::String
    # attribute :location, Valkyrie::Types::String # x,y,w,h
  end

  class TechnicalMetadata < Valkyrie::Resource
    attribute :raw, Valkyrie::Types::String
    attribute :mime_type, Valkyrie::Types::String
    attribute :size, Valkyrie::Types::Integer # Size in Bytes
    attribute :duration, Valkyrie::Types::String
    attribute :md5, Valkyrie::Types::String
    attribute :sha256, Valkyrie::Types::String
  end

  class Transcription < Valkyrie::Resource
    attribute :mime_type, Valkyrie::Types::String
    attribute :contents, Valkyrie::Types::String
    # attribute :type, ORC, caption, human transcribed
  end

  attribute :alternate_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID)
  attribute :original_filename, Valkyrie::Types::String
  attribute :preservation_file_id, Valkyrie::Types::ID
  attribute :preservation_copies_ids, Valkyrie::Types::Set
  attribute :technical_metadata, TechnicalMetadata
  attribute :label, Valkyrie::Types::String

  attribute :annotations, Valkyrie::Types::Array.of(Annotation) # previously, called table of contents

  attribute :derivatives, Valkyrie::Types::Array.of(DerivativeResource)

  attribute :transcriptions, Valkyrie::Types::Array.of(Transcription)

  # attribute :preservation_metadata
end
