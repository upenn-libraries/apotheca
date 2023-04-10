# frozen_string_literal: true

class AssetResource
  # Represent a discrete event in the lifecycle of an AssetResource
  class PreservationEvent < Valkyrie::Resource
    include TrackedEvents

    attribute :identifier, Valkyrie::Types::String
    attribute :event_type, Valkyrie::Types::URI
    attribute :timestamp, Valkyrie::Types::DateTime
    attribute :outcome, Valkyrie::Types::URI
    attribute :outcome_detail_note, Valkyrie::Types::String
    attribute :agent, Valkyrie::Types::String
    attribute :agent_type, Valkyrie::Types::String
    attribute :agent_role, Valkyrie::Types::URI
  end
end
