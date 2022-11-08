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

      it 'fails' do
        expect(result.failure?).to be true
      end

      it 'returns expected failure' do
        expect(result.failure[0]).to be :error_saving_resource
        expect(result.failure[1]).to be_an Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
