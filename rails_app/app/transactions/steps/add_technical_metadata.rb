# frozen_string_literal: true

module Steps
  # Add technical metadata to change set.
  class AddTechnicalMetadata
    include Dry::Monads[:result]

    def call(change_set)
      return Success(change_set) unless change_set.changed?(:preservation_file_id)

      file = change_set.preservation_file

      tech_metadata = fits.examine(contents: file.read, filename: change_set.original_filename)

      return Failure(error: :invalid_mime_type) unless Settings.supported_mime_types.include?(tech_metadata.mime_type)

      change_set.technical_metadata.raw       = tech_metadata.raw
      change_set.technical_metadata.mime_type = tech_metadata.mime_type
      change_set.technical_metadata.size      = tech_metadata.size
      change_set.technical_metadata.width     = tech_metadata.width
      change_set.technical_metadata.height    = tech_metadata.height
      change_set.technical_metadata.md5       = tech_metadata.md5
      change_set.technical_metadata.duration  = tech_metadata.duration
      change_set.technical_metadata.dpi       = tech_metadata.dpi
      change_set.technical_metadata.sha256    = file.checksum(digests: [Digest::SHA256.new]).first

      Success(change_set)
    rescue FileCharacterization::Fits::Error => e
      Failure(error: :file_characterization_failed, exception: e, change_set: change_set)
    end

    private

    def fits
      FileCharacterization::Fits.new(url: Settings.fits.url)
    end

    def preservation_storage
      Valkyrie::StorageAdapter.find(:preservation)
    end
  end
end
