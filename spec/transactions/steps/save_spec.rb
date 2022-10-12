# frozen_string_literal: true

describe Steps::Save do
  let(:item) { persist(:item_resource) }

  describe '#call' do
    let(:save_step) { described_class.new }

    context 'when there is an issue persisting a resource' do
      subject(:result) { save_step.call(ItemChangeSet.new(item)) }

      # Deleting item to trigger a save error.
      before do
        Valkyrie::MetadataAdapter.find(:postgres_solr_persister).persister.delete(resource: item)
      end

      it 'returns a failure' do
        expect(result.failure?).to be true
        expect(result.failure).to be :error_saving_resource
      end
    end
  end
end
