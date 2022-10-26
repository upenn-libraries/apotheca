# frozen_string_literal: true

describe Steps::UpdateArkMetadata do
  let(:update_ark_metadata) { described_class.new }

  describe '#call' do
    let(:item) { persist(:item_resource) }
    let(:result) { update_ark_metadata.call(item) }

    context 'when EZID request invalid' do
      include_context 'with unsuccessful EZID responses'

      it 'fails' do
        expect(result.failure?).to be true
        expect(result.failure).to be :failed_to_update_ezid_metadata
      end
    end
  end
end