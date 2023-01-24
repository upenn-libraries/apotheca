# frozen_string_literal: true

describe DeleteItem do
  let(:transaction) { described_class.new }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service }

  describe '#call' do
    let(:result) { transaction.call(id: item.id) }

    context 'when the Item has no assets' do
      let(:item) { persist(:item_resource) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'removes the Item' do
        expect do
          query_service.find_by(id: result.value![:resource].id)
        end.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when the Item has assets' do
      let(:asset) { persist(:asset_resource) }
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'enqueues job to delete Assets' do
        expect(RemoveAssetJob).to have_been_enqueued.with(
          result.value![:resource].asset_ids.first
        )
      end
    end
  end
end
