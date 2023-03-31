# frozen_string_literal: true

class AssetResource
  class PreservationEvent < Valkyrie::Resource
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
    def self.ingest(outcome:, as:, agent:)
      PreservationEvent.new(
        event_type: ControlledVocabulary.for(:premis_events).find('ingestion')[:value],
        timestamp: DateTime.current,
        outcome: ControlledVocabulary.for(:premis_outcomes).find(outcome.to_s), # TODO: handle failure in another method?
        outcome_detail_note: "Ingested as #{:as}",
        # agent: agent,  # TODO: agent is either a system event or user-init...how to determine?
        # agent_type: 'local',
        # agent_role: ControlledVocabulary.for(:premis_agent_roles).find()
      )
    end

    def self.checksum(outcome:, checksum:, agent:)
      PreservationEvent.new(
        event_type: ControlledVocabulary.for(:premis_events).find_by_label('message digest calculation')[:value],
        timestamp: DateTime.current,
        outcome: ControlledVocabulary.for(:premis_outcomes).find_by_label(outcome.to_s)[:value], # TODO: handle failure how?
        outcome_detail_note: "Checksum for file is #{checksum}",
        # agent: agent,  # TODO: agent is either a system event or user-init...how to determine?
        # agent_type: 'local',
        # agent_role: ControlledVocabulary.for(:premis_agent_roles).find()
        )
    end
  end
end
