# frozen_string_literal: true

# Asset model; contains attributes and helper methods
class AssetResource < Valkyrie::Resource
  DERIVATIVE_TYPES = %w[thumbnail iiif_image access textonly_pdf text hocr].freeze

  include ModificationDetails
  include Lockable

  # Supplemental descriptive notes about an asset
  class Annotation < Valkyrie::Resource
    transform_keys(&:to_sym)

    attribute :text, Valkyrie::Types::Strict::String
    # attribute :location, Valkyrie::Types::String # x,y,w,h
  end

  # Data that describes the digital properties of an asset
  class TechnicalMetadata < Valkyrie::Resource
    attribute :raw, Valkyrie::Types::Strict::String.optional
    attribute :mime_type, Valkyrie::Types::Strict::String.optional
    attribute :size, Valkyrie::Types::Strict::Integer.optional # Size in Bytes
    attribute :width, Valkyrie::Types::Strict::Integer.optional # in pixels
    attribute :height, Valkyrie::Types::Strict::Integer.optional # in pixels
    attribute :dpi, Valkyrie::Types::Strict::Integer.optional # dots/pixels per inch
    attribute :duration, Valkyrie::Types::Strict::Float.optional # in seconds
    attribute :md5, Valkyrie::Types::Strict::String.optional
    attribute :sha256, Valkyrie::Types::String.optional
  end

  # Translation of image, video, or audio into a text format
  class Transcription < Valkyrie::Resource
    transform_keys(&:to_sym)

    attribute :mime_type, Valkyrie::Types::Strict::String
    attribute :contents, Valkyrie::Types::Strict::String
    # attribute :type, ORC, caption, human transcribed
  end

  attribute :original_filename, Valkyrie::Types::Strict::String.optional
  attribute :preservation_file_id, Valkyrie::Types::ID
  attribute :preservation_copies_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
  attribute :technical_metadata, TechnicalMetadata
  attribute :preservation_events, Valkyrie::Types::Array.of(PreservationEvent)
  attribute :label, Dry::Types['params.nil'] | Valkyrie::Types::Strict::String

  attribute :annotations, Valkyrie::Types::Array.of(Annotation) # previously, called table of contents

  attribute :derivatives, Valkyrie::Types::Array.of(DerivativeResource)

  attribute :transcriptions, Valkyrie::Types::Array.of(Transcription)

  # Accessors for derivatives.
  DERIVATIVE_TYPES.each do |symbol|
    define_method symbol do
      derivatives.find { |d| d.type == symbol }
    end
  end

  # Finds pyramidal tiff from either iiif_image or access derivatives
  # @return [DerivativeResource, nil]
  def pyramidal_tiff
    return iiif_image unless image?

    iiif_image || access
  end

  # Return true if asset is an image
  def image?
    technical_metadata.mime_type.start_with?('image')
  end

  # Best title to use when trying to represent asset. In most cases Assets should
  # have a name. If they don't we display the id.
  #
  # @return [String]
  def display_title
    original_filename || id.to_s
  end
end
