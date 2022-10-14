# frozen_string_literal: true

# Transaction that updates an Asset.
class UpdateAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_updated_by, with: 'change_set.require_updated_by'
  step :copy_file_to_preservation_storage
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :add_technical_metadata
  step :mark_stale_derivatives
  step :remove_stale_preservation_backup
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  # step :generate_derivatives # enqueue job to create derivatives
  # step :preservation_file_backup # enqueue job to backup to S3

  def copy_file_to_preservation_storage(file:, **attributes)
    file_resource = preservation_storage.upload(
      file: file, resource: attributes[:resource], original_filename: file.original_filename
    )

    attributes[:preservation_file_id] = file_resource.id
    Success(attributes)
  end

  def add_technical_metadata(change_set)
    Success(change_set) unless change_set.changed?(:preservation_file_id)

    file = preservation_storage.find_by(id: change_set.preservation_file_id)

    fits = FileCharacterization::Fits.new(url: Settings.fits.url)
    tech_metadata = fits.examine(contents: file.read, filename: change_set.original_filename)

    change_set.technical_metadata.raw       = tech_metadata.raw
    change_set.technical_metadata.mime_type = tech_metadata.mime_type
    change_set.technical_metadata.size      = tech_metadata.size
    change_set.technical_metadata.md5       = tech_metadata.md5
    change_set.technical_metadata.duration  = tech_metadata.duration
    change_set.technical_metadata.sha256    = file.checksum digests: [Digest::SHA256.new]

    Success(change_set)
  end

  def mark_stale_derivatives(change_set)
    if change_set.changed?(:preservation_file_id)
      change_set.derivatives.each do |derivative|
        derivative.stale = false
      end
    end
    Success(change_set)
  end

  def remove_stale_preservation_backup(change_set)
    if change_set.changed?(:preservation_file_id)
      preservation_copy_storage = Valkyrie::StorageAdapter.find(:preservation_copy)

      # Deleting derivatives BEFORE new derivatives are created in case derivative generation fails.
      if change_set.preservation_copies_ids.first
        preservation_copy_storage.delete(id: preservation_copies_ids.first)
      end

      change_set.preservation_copies_ids = []

      Success(change_set)
    end
  end

  private

  def preservation_storage
    Valkyrie::StorageAdapter.find(:preservation)
  end
end
