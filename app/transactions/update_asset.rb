# frozen_string_literal: true

# Transaction that updates an Asset.
class UpdateAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_updated_by, with: 'change_set.require_updated_by'
  step :virus_check # TODO: fully implement when virus checking is possible
  step :store_file_in_preservation_storage
  around :cleanup, with: 'asset_resource.cleanup'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :add_technical_metadata, with: 'asset_resource.add_technical_metadata'
  step :mark_stale_derivatives
  step :unlink_stale_preservation_backup
  step :add_preservation_events, with: 'asset_resource.add_preservation_events'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :generate_derivatives
  tee :preservation_backup

  # Wrapping save method in order to delete the old preservation file if a file update is successful.
  def save(change_set)
    # Storing ID for stale preservation backup.
    stale_preservation_backup = change_set.changed?(:preservation_copies_ids) ? change_set.resource.preservation_copies_ids&.first : nil

    result = super(change_set)

    # Delete stale preservation backup file
    if result.success? && stale_preservation_backup
      preservation_copy_storage = Valkyrie::StorageAdapter.find(:preservation_copy)
      preservation_copy_storage.delete(id: stale_preservation_backup)
    end

    result
  end

  def virus_check(**attributes)
    if (attributes[:file] || attributes['file']).present?
      warning = AssetResource::PreservationEvent.virus_check outcome: Premis::Outcomes::WARNING.uri,
                                                             note: 'File present but virus check not performed',
                                                             agent: attributes[:updated_by]
      attributes[:temporary_events] = [warning]
    end

    Success(attributes)
  end

  def store_file_in_preservation_storage(**attributes)
    file = attributes.delete(:file) || attributes.delete('file')

    if file
      file_resource = preservation_storage.upload(
        file: file,
        resource: attributes[:resource],
        original_filename: file.try(:original_filename) || attributes[:original_filename]
      )

      attributes[:preservation_file_id] = file_resource.id
    end

    Success(attributes)
  end

  def mark_stale_derivatives(change_set)
    if change_set.changed?(:preservation_file_id)
      change_set.derivatives.each do |derivative|
        derivative.stale = true
      end
    end
    Success(change_set)
  end

  # Removing connection to stale preservation backup.
  def unlink_stale_preservation_backup(change_set)
    # At this point we won't delete the stale preservation backup in case there is a problem saving the asset.
    change_set.preservation_copies_ids = [] if change_set.changed?(:preservation_file_id)

    Success(change_set)
  end

  # Generates derivatives if they are missing or stale.
  #
  # @param [Valkyrie::Resource] resource
  # @param [Boolean] async runs process asynchronously
  def generate_derivatives(resource, async: true)
    return if resource.preservation_file_id.blank?
    return if resource.derivatives.present? && resource.derivatives.none?(&:stale)

    method = async ? 'perform_later' : 'perform_now'
    GenerateDerivativesJob.send(method, resource.id.to_s)
  end

  # Enqueue job to backup to S3 if backup is not present.
  def preservation_backup(resource)
    return if resource.preservation_file_id.blank? || resource.preservation_copies_ids.present?

    PreservationBackupJob.perform_later(resource.id.to_s)
  end

  private

  def preservation_storage
    Valkyrie::StorageAdapter.find(:preservation)
  end
end
