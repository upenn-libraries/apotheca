# frozen_string_literal: true

module ImportService
  # Represents an imported asset's metadata and file location.
  class AssetData
    attr_accessor :file_location, :metadata

    delegate :file, :checksum_sha256, to: :file_location

    def initialize(file_location: nil, **metadata)
      @file_location = file_location
      @metadata = metadata
    end

    def filename
      metadata[:filename]
    end

    # Checks if file is present in storage.
    def file?
      file_location.present?
    end

    # Make hash representation to send to the resource transactions.
    def resource_attributes
      # In order to support deleting values, a check is necessary to ensure the key is present in the original
      # hash before setting the value. If a value was not provided we should not change that value at all.
      hash = { original_filename: metadata[:filename] }

      hash[:label]          = metadata[:label] if metadata.key?(:label)
      hash[:annotations]    = metadata[:annotation]&.map { |t| { text: t } } if metadata.key?(:annotation)

      if metadata.key?(:transcription)
        hash[:transcriptions] = metadata[:transcription]&.map { |t| { mime_type: 'text/plain', contents: t } }
      end

      hash
    end
  end
end
