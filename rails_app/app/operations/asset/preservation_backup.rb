# frozen_string_literal: true

module Asset
  # Operation that stores an additional copy of our preservation files in a separate location. n
  class PreservationBackup < Operation
    # Stores an additional copy of our preservation files in a separate location.
    #
    # This operation only backups up a preservation file if it isn't already backed up. If you need
    # to override a previously backed up file, it must be deleted before using this operation.
    #
    # @param id [String] UUID of Asset being updated
    # @param updated_by [String] email of user updating the Asset
    def call(id:, updated_by:)
      resource = step find_asset(id)

      change_set = step create_change_set(resource: resource, updated_by: updated_by)
      step store_file_in_backup_location(change_set)
      step add_preservation_events(change_set)
      step validate(change_set)

      resource = step save(change_set)

      record_event(resource)

      resource
    end

    # Saved additional copy of preservation file in backup location.
    #
    # @param change_set [AssetChangeSet]
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

    # @param resource [AssetResource]
    def record_event(resource)
      ResourceEvent.record_event_for(resource: resource, event_type: :preservation_backup)
    end

    # Cleanup: Delete preservation backup created if there was an error.
    #
    # @param failure [Hash] failure data
    def on_failure(failure)
      change_set = failure.fetch(:change_set, nil)

      return unless change_set&.changed?(:preservation_copies_ids) && change_set.preservation_copies_ids.present?

      Valkyrie::StorageAdapter.delete(id: change_set.preservation_copies_ids.first)
    end

    private

    def preservation_storage
      Valkyrie::StorageAdapter.find(:preservation)
    end

    def preservation_copy_storage
      Valkyrie::StorageAdapter.find(:preservation_copy)
    end
  end
end
