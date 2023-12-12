# frozen_string_literal: true

# Shared examples used to check for the presence of a ResourceEvent.

shared_examples 'creates a resource event' do |event_name, initiated_by, json|
  before do
    raise 'resource must be set with `let(:resource)`' unless defined? resource
  end

  it 'records event' do
    event = ResourceEvent.where(resource_identifier: resource.id.to_s, event_type: event_name).first
    expect(event).to be_present
    expect(event).to have_attributes(resource_json: json ? be_a(Hash) : nil, initiated_by: initiated_by,
                                     completed_at: be_a(Time))
  end
end
