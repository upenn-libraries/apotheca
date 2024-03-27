# frozen_string_literal: true

# Transaction that updates an Asset.
class UpdateAsset
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :validate_file_extension
  step :virus_check, with: 'asset_resource.virus_check'
  step :store_file_in_preservation_storage
  around :cleanup, with: 'asset_resource.cleanup'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :add_technical_metadata, with: 'asset_resource.add_technical_metadata'
  step :validate_expected_checksum
  step :mark_stale_derivatives
  step :unlink_stale_preservation_backup
  step :generate_derivatives, with: 'asset_resource.generate_derivatives'
  step :add_preservation_events, with: 'asset_resource.add_preservation_events'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event
  tee :async_derivative_generation
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

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :update_asset)
  end

  # Verify that file has original_filename that ends with a valid extension
  # @param [ActionDispatch::Http::UploadedFile|ImportService::S3Storage::File] file
  def validate_file_extension(**attributes)
    file = attributes[:file] || attributes['file']

    return Success(attributes) if file.blank?
    return Failure(error: :no_original_filename) if file.original_filename.blank?

    extension = File.extname(file.original_filename)

    if Settings.supported_file_extensions.include?(extension.downcase)
      Success(attributes)
    else
      Failure(error: :invalid_file_extension)
    end
  end

  # Validate that the expected_checksum matches the checksum generated by the technical metadata.
  def validate_expected_checksum(change_set)
    if change_set.expected_checksum.present?
      return Failure(error: :expected_checksum_provided_without_file) unless change_set.changed?(:preservation_file_id)
      return Failure(error: :expected_checksum_does_not_match) if change_set.expected_checksum != change_set.technical_metadata.sha256
    end

    Success(change_set)
  end

  # Stores file in preservation storage and adds in the system generated id to the list of
  # attributes passed on to the next step.
  #
  # @param [ActionDispatch::Http::UploadedFile|ImportService::S3Storage::File] file
  def store_file_in_preservation_storage(**attributes)
    file = attributes.delete(:file) || attributes.delete('file')

    if file
      file_resource = preservation_storage.upload(
        file: file,
        resource: attributes[:resource],
        original_filename: file.original_filename
      )

      attributes[:preservation_file_id] = file_resource.id

      # Explicitly set the original filename if file is not being migrated. If file is being migrated
      # store file's original filename in `migrated_filename` in order to record it properly in our
      # preservation events.
      if attributes[:migrated_from].blank?
        attributes[:original_filename] = file.original_filename
      else
        attributes[:migrated_filename] = file.original_filename
      end
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

  # Generate derivatives as part of the update task to prevent retrieving the preservation file multiple times. By
  # default this step is skipped and the derivative files are generated asynchronously.
  #
  # Note: This method is a wrapper around the generate_derivative step defined in the container.
  def generate_derivatives(change_set, skip: true)
    return Success(change_set) if skip || change_set.preservation_file_id.blank?
    return Success(change_set) if change_set.derivatives.present? && change_set.derivatives.none?(&:stale)

    super(change_set)
  end

  # Enqueue a job to generates derivatives if they are missing or stale. Does not attempt to generate derivatives
  # for mime types where derivatives cannot be generated.
  #
  # @param [AssetResource] resource
  def async_derivative_generation(resource)
    return if resource.preservation_file_id.blank?
    return if resource.derivatives.present? && resource.derivatives.none?(&:stale)
    return unless DerivativeService::Asset::Derivatives.generate_for?(resource.technical_metadata.mime_type)

    GenerateDerivativesJob.perform_async(resource.id.to_s, resource.updated_by)
  end

  # Enqueue job to backup to S3 if backup is not present.
  def preservation_backup(resource)
    return if Settings.skip_preservation_backup
    return if resource.preservation_file_id.blank? || resource.preservation_copies_ids.present?

    PreservationBackupJob.perform_async(resource.id.to_s, resource.updated_by)
  end

  private

  def preservation_storage
    Valkyrie::StorageAdapter.find(:preservation)
  end
end
