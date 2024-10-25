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
            note: note, implementer: implementer, timestamp: timestamp
    end

    # @param [String] note
    # @param [String] implementer
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def change_filename(implementer:, note:, timestamp:)
      event type: Premis::Events::FILENAME_CHANGE.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note, implementer: implementer, timestamp: timestamp
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
            note: note, implementer: implementer, timestamp: timestamp
    end

    # @param [String] outcome
    # @param [String] note
    # @param [String] implementer
    # @param [DateTime|nil] timestamp
    # @return [AssetResource::PreservationEvent]
    def virus_check(outcome:, note:, implementer:, timestamp: nil)
      event type: Premis::Events::VIRUS_CHECK.uri,
            outcome: outcome, note: note, implementer: implementer, timestamp: timestamp
    end

    # Used for preservation backup (replication of preservation file).
    #
    # @param [String] note
    # @param [String] implementer
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def replication(note:, implementer:, timestamp:)
      event type: Premis::Events::REPLICATION.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note, implementer: implementer, timestamp: timestamp
    end

    # TODO: these actions remain to be integrated
    def fixity; end
    def tombstone; end

    # @return [String]
    def apotheca
      version = Settings.app_version
      Rails.logger.warn 'Settings.app_version is not present' if version.blank?
      "#{Rails.application.class.module_parent_name} (#{version})"
    end
  end
end
