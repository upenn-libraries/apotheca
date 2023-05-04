# frozen_string_literal: true

# Methods for building common PreservationEvents
module TrackedEvents
  extend ActiveSupport::Concern

  class_methods do
    # @param [String] type
    # @param [String] outcome
    # @param [String] note
    # @param [String] implementer
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def event(type:, outcome:, note:, implementer:, timestamp:)
      AssetResource::PreservationEvent.new(
        identifier: SecureRandom.uuid,
        event_type: type,
        timestamp: timestamp,
        outcome: outcome,
        outcome_detail_note: note,
        implementer: implementer,
        program: apotheca
      )
    end

    # @param [String] note
    # @param [String] implementer
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def checksum(note:, implementer:, timestamp:)
      event type: Premis::Events::CHECKSUM.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note,
            implementer: implementer,
            timestamp: timestamp
    end

    # @param [String] note
    # @param [String] implementer
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def filename_changed(implementer:, note:, timestamp:)
      event type: Premis::Events::EDIT_FILENAME.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note,
            implementer: implementer,
            timestamp: timestamp
    end

    # Used for ingestion, re-ingestion and migration events
    #
    # @param [String] note
    # @param [String] implementer
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def ingestion(note:, implementer:, timestamp:)
      event type: Premis::Events::INGEST.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note,
            implementer: implementer,
            timestamp: timestamp
    end

    # @param [String] outcome
    # @param [String] note
    # @param [String] implementer
    # @param [DateTime|nil] timestamp
    # @return [AssetResource::PreservationEvent]
    def virus_check(outcome:, note:, implementer:, timestamp: nil)
      event type: Premis::Events::VIRUS_CHECK.uri,
            outcome: outcome,
            note: note,
            implementer: implementer,
            timestamp: timestamp
    end

    # TODO: these actions remain to be integrated
    def fixity; end
    def tombstone; end

    # @return [String]
    def apotheca
      Rails.application.class.module_parent_name.to_s
    end
  end
end
