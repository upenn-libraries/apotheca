# frozen_string_literal: true

# Model for keeping track of actions done on Resources.
class ResourceEvent < ApplicationRecord
  validates :event_type, :completed_at, :resource_identifier, presence: true

  def self.record_event_for(event_type:, resource:, initiated_by: nil, json: true)
    attrs = {
      initiated_by: initiated_by || resource.updated_by,
      resource_identifier: resource.id.to_s,
      event_type: event_type,
      completed_at: DateTime.current
    }

    attrs[:resource_json] = resource.to_json if json

    ResourceEvent.create!(**attrs)
  end
end
