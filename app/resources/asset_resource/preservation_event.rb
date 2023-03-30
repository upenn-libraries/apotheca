# frozen_string_literal: true

class AssetResource
  class PreservationEvent < Valkyrie::Resource
    # attribute :identifier, # TODO: either generate a UUID or make this a resource we link to, instead of it being nested.
    attribute :event_type, TermResource
    attribute :timestamp, Valkyrie::Types::DateTime
    attribute :outcome, TermResource
    attribute :outcome_detail_note, Valkyrie::Types::String
    attribute :agent, Valkyrie::Types::String
    attribute :agent_type, Valkyrie::Types::String
    attribute :agent_role, TermResource
  end
end