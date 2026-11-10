# frozen_string_literal: true

describe Asset::Steps::DetachFromItem do
  let(:asset) { persist(:asset_resource) }
  let(:item) { persist(:item_resource, asset_ids: [asset.id]) }
  let(:result) { described_class.new.call(resource: asset, item: item, deleted_by: 'initiator@example.com') }

  describe '#call' do
    context 'when the item is present' do
      it 'calls the operation with the expected arguments' do
        double = Item::DetachAsset.new
        allow(Item::DetachAsset).to receive(:new).and_return(double)
        allow(double).to receive(:call).and_return(Dry::Monads::Success(item))
        result
        expect(double).to have_received(:call).with(asset_id: asset.id, id: item.id,
                                                    updated_by: 'initiator@example.com')
      end
    end

    context 'when the item is not present' do
      let(:item) { nil }

      it 'returns success' do
        expect(result.success?).to be true
      end
    end
  end
end
