# frozen_string_literal: true

module Steps
  # Add preservation events to change set.
  class AddPreservationEvents
    include Dry::Monads[:result]

    EVENT = AssetResource::PreservationEvent

    # @param [AssetChangeSet] change_set
    # @param [Hash] attributes
    def call(change_set, **attributes)
      @change_set = change_set

      # TODO: assume we trickle down the previosu (virus check) events as fully-formed Preservation events. We may need to set the timestamp to the value used here.
      @change_set.preservation_events += Array.wrap(attributes.delete :events)
      add_action_event
      add_checksum_event
      add_filename_events if filename_changed?

      Success(change_set)
    end

    private

    def add_action_event
      type = action_event_type
      return unless type # don't add an ingestion event - no file action

      note_attr = case type
                  when :migration
                    { note: 'Object migrated from Bulwark to Apotheca' }
                  when :ingestion
                    { note: "Object ingested as #{@change_set.original_filename}" }
                  when :reingestion
                    { note: "New file ingested as #{@change_set.original_filename}" }
                  else
                    {} # TODO: return here somehow instead of guard above?
                  end
      event_attrs = { agent: @change_set.updated_by, timestamp: timestamp}.merge note_attr
      @change_set.preservation_events << EVENT.ingestion(**event_attrs)
    end

    def add_checksum_event
      checksum = @change_set.technical_metadata.sha256.first
      @change_set.preservation_events << EVENT.checksum(
        note: "Checksum for file is #{checksum}",
        agent: @change_set.updated_by,
        timestamp: timestamp
      )
    end

    # @return [TrueClass, FalseClass]
    def filename_changed?
      @change_set.resource.original_filename != @change_set.original_filename
    end

    def add_filename_events
      @change_set.preservation_events << EVENT.filename_changed(
        agent: @change_set.updated_by,
        note: "File's original filename renamed from #{@change_set.resource.original_filename} to #{@change_set.original_filename}",
        timestamp: timestamp
      )
    end

    # @return [Symbol | nil]
    def action_event_type
      if @change_set.migrated_object
        :migration
      elsif @change_set.resource.preservation_file_id.blank? && @change_set.preservation_file_id.present?
        # resource ID is blank but an ID is set in the ChangeSet
        # TODO: this is not working to detect an new record. above values are equal. resource.persisted? returns true???
        :ingestion
      elsif (@change_set.resource.preservation_file_id.present? && @change_set.preservation_file_id.present?) &&
            (@change_set.resource.preservation_file_id != @change_set.preservation_file_id)
        # resource ID is set and a new ID is incoming in the ChangeSet, and they aren't the same
        :reingestion
      end
      # no change to file - log no ingestion action
    end

    # @return [DateTime]
    def timestamp
      @timestamp ||= DateTime.current
    end
  end
end
