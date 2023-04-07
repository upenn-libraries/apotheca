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
      action = action_event_type(change_set)
      timestamp = DateTime.current
      events = []

      events += preceding_events(change_set, timestamp)
      events << action_event(action, change_set, timestamp)
      events << checksum_event(action, change_set, timestamp)
      events << filename_event(action, change_set, timestamp)

      change_set.preservation_events += events.compact

      Success(change_set)
    end

    private

    # Determine event type based on the change being made to the associated preservation file, which occurs prior
    # in the transaction (see add_preservation_file method in UpdateAsset transaction). If no file change is detected,
    # consider the action a metadata update and do not log any ingestion or related events.
    # @return [Symbol]
    # @param [Valkyrie::ChangeSet] change_set
    def action_event_type(change_set)
      if change_set.migrated_object
        :migration
      elsif change_set.resource.preservation_file_id.blank? && change_set.preservation_file_id.present?
        # resource ID is blank but an ID is set in the ChangeSet
        :ingestion
      elsif (change_set.resource.preservation_file_id.present? && change_set.preservation_file_id.present?) &&
            (change_set.resource.preservation_file_id != change_set.preservation_file_id)
        # resource ID is set and a new ID is incoming in the ChangeSet, and they aren't the same
        :reingestion
      else
        :metadata_update
      end
    end

    # Events may be built earlier in the transaction and stored on the temporary events virtual attribute.
    # Set the timestamp on any of these temporary events so that they are consistent with other events in
    # the transaction
    # @return [Array<AssetResource::PreservationEvent>]
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    def preceding_events(change_set, timestamp)
      Array.wrap(change_set.temporary_events).map do |event|
        event.timestamp = timestamp
        event
      end
    end

    # Returns an Event for the ingestion action type - nil if no action on the file is performed
    # @param [Symbol] action
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent | NilClass]
    def action_event(action, change_set, timestamp)
      note = case action
             when :migration then 'Object migrated from Bulwark to Apotheca'
             when :ingestion then "Object ingested as #{change_set.original_filename}"
             when :reingestion then "New file ingested as #{change_set.original_filename}"
             else
               return
             end
      event_attrs = { agent: change_set.updated_by, timestamp: timestamp, note: note }
      EVENT.ingestion(**event_attrs)
    end

    # Return a checksum event. This requires that technical metadata be set in a prior transaction step.
    # See AddTechnicalMetadata step.
    # @param [Symbol] action
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def checksum_event(action, change_set, timestamp)
      return if action == :metadata_update

      # TODO: throws exception if no tech md set, but at this point in the transaction, tech md should always be set
      checksum = change_set.technical_metadata.sha256.first
      EVENT.checksum(
        note: "Checksum for file is #{checksum}",
        agent: change_set.updated_by,
        timestamp: timestamp
      )
    end

    # Returns an event for a filename change. Base the detail note of the event on the type of change. Include
    # appropriate previous and current filename values.
    # @param [Symbol] action
    # @param [Valkyrie::ChangeSet] change_set
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def filename_event(action, change_set, timestamp)
      return if action == :metadata_update

      # get current filename - in ingestion case, we want to get the original filename of the file because we have no
      # identifier from storage yet to use as current filename
      current_filename = action == :ingestion ? change_set.original_filename : file_name(change_set.resource)
      EVENT.filename_changed(
        agent: change_set.updated_by,
        note: "File's original filename renamed from #{current_filename} to #{file_name(change_set)}",
        timestamp: timestamp
      )
    end

    # Returns a semi-user friendly "filename" from a change set or a resource. Could be a string filename or a UUID
    # extracted from a Valkyrie::ID
    # @param [AssetResource | AssetChangeSet] source
    # @return [String]
    def file_name(source)
      return source.original_filename if source.preservation_file_id.blank?

      source.preservation_file_id.id.split('/').last
    end
  end
end
