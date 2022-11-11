# frozen_string_literal: true

module Steps
  # Add technical metadata to change set.
  class AddTechnicalMetadata
    include Dry::Monads[:result]

    def call(change_set)
      return Success(change_set) unless change_set.changed?(:preservation_file_id)

      file = preservation_storage.find_by(id: change_set.preservation_file_id)

      tech_metadata = fits.examine(contents: file.read, filename: change_set.original_filename)

      change_set.technical_metadata.raw       = tech_metadata.raw
      change_set.technical_metadata.mime_type = tech_metadata.mime_type
      change_set.technical_metadata.size      = tech_metadata.size
      change_set.technical_metadata.md5       = tech_metadata.md5
      change_set.technical_metadata.duration  = tech_metadata.duration
      change_set.technical_metadata.sha256    = file.checksum digests: [Digest::SHA256.new]

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
