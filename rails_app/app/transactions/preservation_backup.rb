# frozen_string_literal: true

# Transaction that stores an additional copy of our preservation files in a separate location.
#
# This transaction only backups up a preservation file, if it isn't already backed up. If you need
# to override a previously backed up file, it must be deleted before using this transaction
class PreservationBackup
  include Dry::Transaction(container: Container)

  step :find_asset, with: 'asset_resource.find_resource'
  step :require_updated_by, with: 'attributes.require_updated_by'
  step :create_change_set, with: 'asset_resource.create_change_set'
  step :store_file_in_backup_location
  step :add_preservation_events, with: 'asset_resource.add_preservation_events'
  around :cleanup, with: 'asset_resource.cleanup'
  step :validate, with: 'change_set.validate'
  step :save, with: 'change_set.save'
  tee :record_event

  def record_event(resource)
    ResourceEvent.record_event_for(resource: resource, event_type: :preservation_backup)
  end

  def store_file_in_backup_location(change_set)
    return Success(change_set) if change_set.preservation_copies_ids.present?

    file = preservation_storage.find_by(id: change_set.preservation_file_id)

    backup_file = preservation_copy_storage.upload(
      file: file,
      resource: change_set.resource,
      original_filename: change_set.original_filename,
      content_type: change_set.technical_metadata.mime_type
    )

    change_set.preservation_copies_ids = [backup_file.id]

    Success(change_set)
  end

  private

  def preservation_storage
    Valkyrie::StorageAdapter.find(:preservation)
  end

  def preservation_copy_storage
    Valkyrie::StorageAdapter.find(:preservation_copy)
  end
end
