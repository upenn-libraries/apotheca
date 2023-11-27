# frozen_string_literal: true

shared_examples_for 'TrackedEvents' do
  before do
    raise 'resource_klass must be set with `let(:resource_klass)`' unless
      defined? resource_klass
  end

  describe '.event' do
    let(:event) do
      resource_klass.event(
        type: Premis::Events::FILENAME_CHANGE.uri, outcome: Premis::Outcomes::SUCCESS.uri,
        note: 'An important filename change happened', implementer: 'admin@upenn.edu', timestamp: DateTime.current
      )
    end

    it 'sets program' do
      expect(event.program).to start_with('Apotheca')
    end

    it 'sets identifier' do
      expect(event.identifier).not_to be_nil
    end
  end

  describe '.apotheca' do
    before do
      allow(Settings).to receive(:app_version).and_return('v1.0.0')
    end

    it 'returns application name and version' do
      expect(resource_klass.apotheca).to eql 'Apotheca (v1.0.0)'
    end
  end
end
