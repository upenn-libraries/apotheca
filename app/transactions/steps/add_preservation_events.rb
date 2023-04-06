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
      @action = action_event_type

      add_preceding_events events: attributes.delete(:events)
      add_action_event
      if @action != :metadata_update
        add_checksum_event
        add_filename_events
      end

      Success(change_set)
    end

    private

    def add_action_event
      note_attr = case @action
                  when :migration
                    { note: 'Object migrated from Bulwark to Apotheca' }
                  when :ingestion
                    { note: "Object ingested as #{@change_set.original_filename}" }
                  when :reingestion
                    { note: "New file ingested as #{@change_set.original_filename}" }
                  else
                    return
                  end
      event_attrs = { agent: @change_set.updated_by, timestamp: timestamp}.merge note_attr
      @change_set.preservation_events << EVENT.ingestion(**event_attrs)
    end

    # @param [AssetResource::PreservationEvent|Array] events
    def add_preceding_events(events:)
      events = Array.wrap(events).each do |event|
        event.timestamp = timestamp
      end
      @change_set.preservation_events += events
    end

    def add_checksum_event
      checksum = @change_set.technical_metadata.sha256.first
      @change_set.preservation_events << EVENT.checksum(
        note: "Checksum for file is #{checksum}",
        agent: @change_set.updated_by,
        timestamp: timestamp
      )
    end

    def add_filename_events
      @change_set.preservation_events << EVENT.filename_changed(
        agent: @change_set.updated_by,
        note: "File's original filename renamed from #{file_name(source: @change_set.resource)} to #{file_name(source: @change_set)}",
        timestamp: timestamp
      )
    end

    # @return [Symbol | nil]
    def action_event_type
      if @change_set.migrated_object
        :migration
      elsif @change_set.resource.preservation_file_id.blank? && @change_set.preservation_file_id.present?
        # resource ID is blank but an ID is set in the ChangeSet
        :ingestion
      elsif (@change_set.resource.preservation_file_id.present? && @change_set.preservation_file_id.present?) &&
            (@change_set.resource.preservation_file_id != @change_set.preservation_file_id)
        # resource ID is set and a new ID is incoming in the ChangeSet, and they aren't the same
        :reingestion
      else
        :metadata_update
      end
    end

    # @return [DateTime]
    def timestamp
      @timestamp ||= DateTime.current
    end

    # @param [AssetResource | AssetChangeSet] source
    # @return [String]
    def file_name(source:)
      return source.original_filename if source.preservation_file_id.blank?

      source.preservation_file_id.id.split('/').last
    end
  end
end
