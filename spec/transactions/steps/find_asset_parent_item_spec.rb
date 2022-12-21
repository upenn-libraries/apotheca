# frozen_string_literal: true

describe Steps::FindAssetParentItem do
  let(:asset) { persist(:asset_resource) }
  let(:result) { described_class.new.call(resource: asset) }

  describe '#call' do
    context 'when asset has no item' do
      it 'returns the asset and nil' do
        expect(result.value![:asset]).to eq asset
        expect(result.value![:item]).to be_nil
      end
    end

    context 'when asset has one parent item' do
      let(:item) { persist(:item_resource, asset_ids: [asset.id]) }

      it 'returns the asset and the item' do
        item_id = item.id # ensure item is instantiated prior to determining result
        expect(result.value![:asset]).to eq asset
        expect(result.value![:item].id).to eq item_id
      end
    end

    context 'when asset has multiple parent items' do
      it 'returns an error' do
        2.times { persist(:item_resource, asset_ids: [asset.id]) }
        expect(result).to be_failure
        expect(result.failure[:error]).to eq :multiple_parent_items_found
      end
    end
  end
end
