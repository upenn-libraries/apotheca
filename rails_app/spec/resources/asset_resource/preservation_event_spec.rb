# frozen_string_literal: true

require_relative '../concerns/tracked_events'

describe AssetResource::PreservationEvent do
  let(:resource_klass) { described_class }

  it_behaves_like 'TrackedEvents'
end
