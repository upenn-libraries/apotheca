# frozen_string_literal: true

shared_examples_for 'Lockable' do |factory|
  let(:resource) { persist(factory) }

  describe '#lockable?' do
    it 'returns true' do
      expect(resource.lockable?).to be true
    end
  end
end
