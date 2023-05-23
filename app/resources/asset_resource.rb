# frozen_string_literal: true

# Asset model; contains attributes and helper methods
class AssetResource < Valkyrie::Resource
  include ModificationDetails
  include Lockable

  # Supplemental descriptive notes about an asset
  class Annotation < Valkyrie::Resource
    attribute :text, Valkyrie::Types::String
    # attribute :location, Valkyrie::Types::String # x,y,w,h
  end

  # Data that describes the digital properties of an asset
  class TechnicalMetadata < Valkyrie::Resource
    attribute :raw, Valkyrie::Types::String
    attribute :mime_type, Valkyrie::Types::String
    attribute :size, Valkyrie::Types::Integer # Size in Bytes
    attribute :duration, Valkyrie::Types::String
    attribute :md5, Valkyrie::Types::String
    attribute :sha256, Valkyrie::Types::String
  end

  # Translation of image, video, or audio into a text format
  class Transcription < Valkyrie::Resource
    attribute :mime_type, Valkyrie::Types::String
    attribute :contents, Valkyrie::Types::String
    # attribute :type, ORC, caption, human transcribed
  end

  attribute :alternate_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID)
  attribute :original_filename, Valkyrie::Types::String
  attribute :preservation_file_id, Valkyrie::Types::ID
  attribute :preservation_copies_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
  attribute :technical_metadata, TechnicalMetadata
  attribute :preservation_events, Valkyrie::Types::Array.of(PreservationEvent)
  attribute :label, Valkyrie::Types::String

  attribute :annotations, Valkyrie::Types::Array.of(Annotation) # previously, called table of contents

  attribute :derivatives, Valkyrie::Types::Array.of(DerivativeResource)

  attribute :transcriptions, Valkyrie::Types::Array.of(Transcription)

  # attribute :preservation_metadata

  # @return [DerivativeResource]
  def thumbnail
    derivatives.find do |d|
      return d if d.thumbnail?
    end
  end

  # @return [DerivativeResource]
  def access
    derivatives.find do |d|
      return d if d.access?
    end
  end

  # Best title to use when trying to represent asset. In most cases Assets should
  # have a name. If they don't we display the id.
  #
  # @return [String]
  def display_title
    original_filename || id.to_s
  end
end
