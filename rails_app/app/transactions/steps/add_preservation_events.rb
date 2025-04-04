# frozen_string_literal: true

module Steps
  # Add preservation events to change set.
  class AddPreservationEvents
    include Dry::Monads[:result]

    EVENT = AssetResource::PreservationEvent

    # Add relevant preservation events to the ChangeSet. First by processing any preceding events set by previous
    # transaction steps, then events related to file additions or modifications. Timestamps are consistent across all
    # events added in the transaction to reflect the fact that they occur in a single discrete transaction.
    # TODO: rescue exceptions?
    # @param [Valkyrie::ChangeSet] change_set
    def call(change_set)
      timestamp = DateTime.current
      events = []

      events += preceding_events(change_set, timestamp)
      events += preservation_file_events(change_set, timestamp)
      events << original_filename_event(change_set, timestamp)
      events << replication_event(change_set, timestamp)

      change_set.preservation_events += events.compact

      Success(change_set)
    end

    private

    # Log changes to the preservation file. Determine ingestion event type and then log ingestion and related events.
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [Array<AssetResource::PreservationEvent>]
    def preservation_file_events(change_set, timestamp)
      ingestion_type = ingestion_event_type(change_set)

      return [] unless ingestion_type

      [
        ingestion_event(ingestion_type, change_set, timestamp),
        checksum_event(change_set, timestamp),
        preservation_filename_event(ingestion_type, change_set, timestamp)
      ]
    end

    # Determine ingestion event type based on the change being made to the associated preservation file, which occurs
    # prior in the transaction (see add_preservation_file method in UpdateAsset transaction). If no file change is
    # detected, return nil.
    # @param [Valkyrie::ChangeSet] change_set
    # @return [Symbol|nil]
    def ingestion_event_type(change_set)
      if change_set.migrated_from.present?
        :migration
      elsif change_set.resource.preservation_file_id.blank? && change_set.preservation_file_id.present?
        # resource ID is blank but an ID is set in the ChangeSet
        :ingestion
      elsif (change_set.resource.preservation_file_id.present? && change_set.preservation_file_id.present?) &&
            (change_set.changed? :preservation_file_id)
        # resource ID is set and a new ID is incoming in the ChangeSet, and they aren't the same
        :reingestion
      end
    end

    # Events may be built earlier in the transaction and stored on the temporary events virtual attribute.
    # Set the timestamp on any of these temporary events so that they are consistent with other events in
    # the transaction
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [Array<AssetResource::PreservationEvent>]
    def preceding_events(change_set, timestamp)
      Array.wrap(change_set.temporary_events).map do |event|
        event.timestamp = timestamp
        event
      end
    end

    # Returns an Event for the ingestion type - nil if no action on the file is performed
    # @param [Symbol] ingestion_type
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent | NilClass]
    def ingestion_event(ingestion_type, change_set, timestamp)
      note = case ingestion_type
             when :migration
               I18n.t('preservation_events.migration.note', from: change_set.migrated_from)
             when :ingestion
               I18n.t('preservation_events.ingestion.note', filename: change_set.original_filename)
             when :reingestion
               I18n.t('preservation_events.reingestion.note', filename: change_set.original_filename)
             else return; end

      EVENT.ingestion implementer: change_set.updated_by, timestamp: timestamp, note: note
    end

    # Return a checksum event. This requires that technical metadata be set in a prior transaction step.
    # See AddTechnicalMetadata step.
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def checksum_event(change_set, timestamp)
      # TODO: throws exception if no tech md set, but at this point in the transaction, tech md should always be set
      checksum = change_set.technical_metadata.sha256
      EVENT.checksum(
        note: I18n.t('preservation_events.checksum.note', checksum: checksum),
        implementer: change_set.updated_by,
        timestamp: timestamp
      )
    end

    # Returns an event for a metadata change in the original_filename field
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def original_filename_event(change_set, timestamp)
      return unless change_set.changed? :original_filename

      from = change_set.resource.original_filename || I18n.t('preservation_events.original_filename.nil_placeholder')

      EVENT.change_filename(
        implementer: change_set.updated_by,
        note: I18n.t('preservation_events.original_filename.note', from: from, to: change_set.original_filename),
        timestamp: timestamp
      )
    end

    # Returns an event for a preservation file change. Base the detail note of the event on the type of change.
    # Include appropriate previous and current filename values.
    # @param [Symbol] ingestion_type
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def preservation_filename_event(ingestion_type, change_set, timestamp)
      previous_filename = previous_preservation_filename(ingestion_type, change_set)

      EVENT.change_filename(
        implementer: change_set.updated_by,
        note: I18n.t('preservation_events.preservation_filename.note',
                     from: previous_filename, to: normalized_filename(change_set.preservation_file_id)),
        timestamp: timestamp
      )
    end

    # Return an event when a preservation file has been backed up (replicated).
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def replication_event(change_set, timestamp)
      return unless change_set.preservation_copies_ids.present? && change_set.changed?(:preservation_copies_ids)

      filename = normalized_filename(change_set.preservation_copies_ids.first)

      EVENT.replication(
        implementer: change_set.updated_by,
        note: I18n.t('preservation_events.replication.note', filename: filename),
        timestamp: timestamp
      )
    end

    # Return the filename of the "previous" preservation file.
    #
    # In the ingestion case, we want to get the original filename of the file because we have no
    #   identifier from storage yet to use as current filename.
    # In the migration case, we use the migrated_filename extracted during processing.
    # In the re-ingestion case, we extract the preservation filename from the unchanged resource.
    def previous_preservation_filename(ingestion_type, change_set)
      case ingestion_type
      when :ingestion
        change_set.original_filename
      when :migration
        change_set.migrated_filename
      when :reingestion
        normalized_filename(change_set.resource.preservation_file_id)
      end
    end

    # Returns a semi-user friendly "filename" from a change set or a resource. This method strips out the leading
    # characters stored in a Valkyrie::ID that represent the file store.
    #
    # @param [Valkyrie::ID] source
    # @return [String]
    def normalized_filename(source)
      source.id.split('://').last
    end
  end
end
