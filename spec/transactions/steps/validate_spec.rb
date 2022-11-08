# frozen_string_literal: true

describe Steps::Validate do
  describe '#call' do
    let(:validate_step) { described_class.new }

    context 'when saving raises an error' do
      subject(:result) { validate_step.call(change_set) }

      let(:change_set) { AssetChangeSet.new(AssetResource.new) }

      it 'returns a failure' do
        expect(result.failure?).to be true
      end

      it 'returns error messages' do
        expect(result.failure.first).to be :validation_failed
        expect(
          result.failure.second.errors.messages
        ).to include(created_by: ['can\'t be blank', 'is invalid'], updated_by: ['can\'t be blank', 'is invalid'])
      end
    end
  end
end
