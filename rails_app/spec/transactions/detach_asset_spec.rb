# frozen_string_literal: true

describe DetachAsset do
  let(:transaction) { described_class.new }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:postgres_solr_persister).query_service }

  describe '#call' do
    let(:result) { transaction.call(id: item.id, asset_id: asset.id, updated_by: asset.updated_by) }

    context 'when updated_by is missing' do
      let(:result) { transaction.call(id: item.id, asset_id: asset.id) }
      let(:item) { persist(:item_resource, :with_asset) }
      let(:asset) { query_service.find_by id: item.asset_ids.first }

      it 'fails' do
        expect(result.failure?).to be true
      end
    end

    context 'when asset attached to item' do
      let(:item) { persist(:item_resource, :with_assets_all_arranged) }
      let(:asset) { query_service.find_by id: item.asset_ids.second }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'removes asset from asset_ids and arranged_asset_ids' do
        updated_item = result.value!
        expect(updated_item.structural_metadata.arranged_asset_ids).not_to include(asset.id)
        expect(updated_item.asset_ids).not_to include(asset.id)
      end
    end

    context 'when asset is thumbnail and other assets are present' do
      let(:item) { persist(:item_resource, :with_assets_all_arranged) }
      let(:asset) { query_service.find_by id: item.thumbnail_asset_id }

      it 'fails and returns descriptive error' do
        expect(result.failure?).to be true
        expect(result.failure[:error]).to include 'thumbnail'
      end
    end

    context 'when asset is thumbnail and no other assets are present' do
      let(:item) { persist(:item_resource, :with_asset) }
      let(:asset) { query_service.find_by id: item.thumbnail_asset_id }

      it 'is successful' do
        expect(result.success?).to be true
      end

      it 'detaches asset' do
        updated_item = result.value!
        expect(updated_item.thumbnail_asset_id).to be_nil
        expect(updated_item.asset_ids).to be_empty
      end
    end
  end
end
