# frozen_string_literal: true

# Methods for building common PreservationEvents
module TrackedEvents
  extend ActiveSupport::Concern

  SYSTEM_AGENT = 'system_user@upenn.edu' # TODO: how will we denote a system-initiated action?

  class_methods do
    # @param [String] type
    # @param [String] outcome
    # @param [String] note
    # @param [String] agent
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def event(type:, outcome:, note:, agent:, timestamp:)
      AssetResource::PreservationEvent.new(
        identifier: SecureRandom.uuid,
        event_type: type,
        timestamp: timestamp,
        outcome: outcome,
        outcome_detail_note: note,
        agent: agent,
        agent_type: 'local',
        agent_role: agent_role(agent)
      )
    end

    # @param [String] note
    # @param [String] agent
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def checksum(note:, agent:, timestamp:)
      event type: Premis::Events::CHECKSUM.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note,
            agent: agent,
            timestamp: timestamp
    end

    # @param [String] note
    # @param [String] agent
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def filename_changed(agent:, note:, timestamp:)
      event type: Premis::Events::EDIT_FILENAME.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note,
            agent: agent,
            timestamp: timestamp
    end

    # Used for ingestion, re-ingestion and migration events
    #
    # @param [String] note
    # @param [String] agent
    # @param [DateTime] timestamp
    # @return [AssetResource::PreservationEvent]
    def ingestion(note:, agent:, timestamp:)
      event type: Premis::Events::INGEST.uri,
            outcome: Premis::Outcomes::SUCCESS.uri,
            note: note,
            agent: agent,
            timestamp: timestamp
    end

    # @param [String] outcome
    # @param [String] note
    # @param [String] agent
    # @param [DateTime|nil] timestamp
    # @return [AssetResource::PreservationEvent]
    def virus_check(outcome:, note:, agent:, timestamp: nil)
      event type: Premis::Events::VIRUS_CHECK.uri,
            outcome: outcome,
            note: note,
            agent: agent,
            timestamp: timestamp
    end

    # TODO: these actions remain to be integrated
    def fixity; end
    def tombstone; end

    def agent_role(agent)
      return Premis::Roles::IMPLEMENTER.uri unless agent == SYSTEM_AGENT

      Premis::Roles::PROGRAM.uri
    end
  end
end
