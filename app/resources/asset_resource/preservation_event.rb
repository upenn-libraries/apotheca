# frozen_string_literal: true

class AssetResource
  class PreservationEvent < Valkyrie::Resource
    SYSTEM_AGENT = 'system_user@upenn.edu' # TODO: how will we denote a system-initiated action?

    attribute :identifier
    attribute :event_type, Valkyrie::Types::URI
    attribute :timestamp, Valkyrie::Types::DateTime
    attribute :outcome, Valkyrie::Types::URI
    attribute :outcome_detail_note, Valkyrie::Types::String
    attribute :agent, Valkyrie::Types::String
    attribute :agent_type, Valkyrie::Types::String
    attribute :agent_role, Valkyrie::Types::URI

    # @param [Object] outcome
    # @param [Object] as
    # def self.ingest(outcome:, as:, agent:)
    #   PreservationEvent.new(
    #     event_type: Premis::Events::INGEST.uri,
    #     timestamp: DateTime.current,
    #     outcome: Premis::Outcomes::SUCCESS.uri, # TODO: handle failure in another method?
    #     outcome_detail_note: "Ingested as #{:as}",
    #     # agent: agent,
    #     # agent_type: 'local',
    #     # agent_role: ''
    #   )
    # end

    def self.checksum_success(checksum:, agent:)
      PreservationEvent.new(
        event_type: Premis::Events::CHECKSUM.uri,
        timestamp: DateTime.current,
        outcome: Premis::Outcomes::SUCCESS.uri,
        outcome_detail_note: "Checksum for file is #{checksum}",
        agent: agent,
        agent_type: 'local',
        agent_role: agent_role(agent)
      )
    end

    def self.checksum_failed(error:, agent:)
      PreservationEvent.new(
        event_type: Premis::Events::CHECKSUM.uri,
        timestamp: DateTime.current,
        outcome: Premis::Outcomes::FAILURE.uri,
        outcome_detail_note: "Checksum generation failed: #{error}",
        agent: agent,
        agent_type: 'local',
        agent_role: agent_role(agent)
      )
    end

    def self.agent_role(agent)
      return Premis::Roles::IMPLEMENTER.uri unless agent == SYSTEM_AGENT

      Premis::Roles::PROGRAM.uri
    end
  end
end
