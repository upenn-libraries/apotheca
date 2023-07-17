# frozen_string_literal: true

class AssetResource
  # Represent a discrete event in the lifecycle of an AssetResource
  class PreservationEvent < Valkyrie::Resource
    include TrackedEvents

    attribute :identifier, Valkyrie::Types::Strict::String
    attribute :event_type, Valkyrie::Types::URI
    attribute :timestamp, Valkyrie::Types::Strict::DateTime.optional
    attribute :outcome, Valkyrie::Types::URI
    attribute :outcome_detail_note, Valkyrie::Types::Strict::String
    attribute :implementer, Valkyrie::Types::Strict::String
    attribute :program, Valkyrie::Types::Strict::String
  end
end
